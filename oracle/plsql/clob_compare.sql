CREATE OR REPLACE PACKAGE clob_compare AS
  /*=========================================================================================================
    NAME: CLOB_COMPARE
    PURPOSE: Provide the interface to compare two text files (clob format)
             Line by Line
    DESCRIPTION: I wrote this package for fun in order to be able to compare with PL/SQL code
                 the changes between to packages saved as CLOBs. But it can be used to compare
                 any two CLOBs where the only restriction is the maximum line length (4000).
                 It is based on the naive Longest Common Subsequence algorithm described here:

                     http://en.wikipedia.org/wiki/Longest_common_subsequence_problem
                     http://en.wikipedia.org/wiki/Diff

                 The code optimizations of Reducing the problem set and Reducing the comparison
                 time are included.

    REVISIONS:
    Version    Date        Author           Description
    ---------  ----------  ---------------  ------------------------------------------------------------
    1.0        2011-04-05  Manuel Vidigal   First Version.
    1.1        2011-04-15  Manuel Vidigal   Fixed bug found by Dave_Five when the rigth side of the
                                            differences was bigger than the left was raising
                                            ORA-06533: "Subscript beyond count"
                                            Taken into consideration the best reading plan of the Matrix
                                            based on the LCS Length of the two reading types.
  https://www.codeproject.com/Articles/177651/CLOB-Comparison-Line-by-Line-in-PL-SQL

    Copyright © 2011 to Manuel Vidigal
    All Rights Reserved

    Redistribution and use in source and binary forms, with or without modification, are permitted
    provided that the following conditions are met:
      ? Redistributions of source code must retain the above copyright notice, this list of
        conditions and the following disclaimer.
      ? Redistributions in binary form must reproduce the above copyright notice, this list of
        conditions and the following disclaimer in the documentation and/or other materials provided
        with the distribution.
      ? Neither the name of the copyright owners nor the names of its contributors may be used to
        endorse or promote products derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
    OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
    CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
    WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  ===========================================================================================================*/
  TYPE t_differences IS RECORD
  (
    old_line_number NUMBER,
    old_file        VARCHAR2(4000),
    status          VARCHAR2(20),
    new_line_number NUMBER,
    new_file        VARCHAR2(4000)
  );

  TYPE t_differences_array is table of t_differences;
  TYPE t_varchar2_array IS TABLE OF VARCHAR2(4000);
  ------------------
  -- Global Types --
  ------------------
  TYPE t_number_array IS TABLE OF NUMBER;
  TYPE t_bidimensional_number_array IS TABLE OF t_number_array;
  -- =================================================================================
  --  NAME:    COMPARE_LINE_BY_LINE
  --  PURPOSE: Function that retrieves two CLOBs and outputs an array with the
  --           differences between them (line by line)
  -- =================================================================================
  FUNCTION compare_line_by_line(old_file_i IN CLOB,
                                new_file_i IN CLOB) RETURN t_differences_array;

  FUNCTION compare_line_by_line_PIPE(old_file_i IN CLOB,
                                new_file_i IN CLOB) RETURN t_differences_array PIPELINED ;
  -- =================================================================================
  --  NAME:    COMPARE_LINE_BY_LINE_REFCURSOR
  --  PURPOSE: Function that retrieves two CLOBs and outputs a SYS_REFCURSOR with the
  --           differences between them (line by line)
  -- =================================================================================
  FUNCTION compare_line_by_line_refcursor(old_file_i IN CLOB,
                                          new_file_i IN CLOB) RETURN SYS_REFCURSOR;
END clob_compare;
/















CREATE OR REPLACE PACKAGE BODY clob_compare AS
  -- =================================================================================
  --  NAME:    READ_CLOB_LINE
  --  PURPOSE: Function that reads a CLOB line starting from start_position_io
  --           until the end of line (chr(10))
  --           If the line is bigger than 4000 Character Raises Error
  -- =================================================================================
  FUNCTION read_clob_line(clob_i            IN CLOB,
                          start_position_io IN OUT NUMBER) RETURN VARCHAR2 IS
    -- Local Variables
    l_line         VARCHAR2(4000);
    l_end_position NUMBER;
    l_file_length  NUMBER;
  BEGIN
    ---------------------
    -- Get CLOB length --
    ---------------------
    l_file_length := sys.dbms_lob.getlength(clob_i);
    ----------------------------------------------------
    -- Get the CLOB end position for the current line --
    ----------------------------------------------------
    l_end_position := dbms_lob.instr(lob_loc => clob_i, pattern => chr(10), offset => start_position_io);
    -------------------------------------
    -- Check if line size is supported --
    -------------------------------------
    IF l_end_position - start_position_io > 4000 THEN
      raise_application_error(-20000, 'The Maximum supported line size for the input files is 4000.');
    END IF;
    -------------------------------
    -- If it's not the last line --
    -------------------------------
    IF l_end_position > 0 THEN
      -------------------
      -- Retrieve Line --
      -------------------
      l_line := rtrim(dbms_lob.substr(lob_loc => clob_i,
                                      amount  => least(l_end_position - start_position_io, 4000),
                                      offset  => start_position_io),
                      chr(13) || chr(10));
      ---------------------------------
      -- Mark the new start position --
      ---------------------------------
      start_position_io := l_end_position + 1;
      ------------------
      -- If last line --
      ------------------
    ELSE
      -------------------
      -- Retrieve Line --
      -------------------
      l_line := dbms_lob.substr(lob_loc => clob_i,
                                amount  => l_file_length - start_position_io + 1,
                                offset  => start_position_io);
      --------------------------------------
      -- Mark start position as finnished --
      --------------------------------------
      start_position_io := 0;
    END IF;
    --
    RETURN l_line;
  END read_clob_line;
  -- =================================================================================
  --  NAME:    CLOB_TO_ARRAY
  --  PURPOSE: Function that returns an array with all CLOB lines
  -- =================================================================================
  FUNCTION clob_to_array(clob_i IN CLOB) RETURN t_varchar2_array IS
    -- Local Variables
    l_array          t_varchar2_array := t_varchar2_array();
    l_start_position NUMBER := 1;
  BEGIN
    --------------------------------
    -- While there is a next line --
    --------------------------------
    WHILE l_start_position != 0
    LOOP
      -----------------------------------
      -- Populate array with clob line --
      -----------------------------------
      l_array.extend;
      l_array(l_array.count) := read_clob_line(clob_i, l_start_position);
    END LOOP;
    --
    RETURN l_array;
  END clob_to_array;
  -- =================================================================================
  --  NAME:    GET_START_END_LINES
  --  PURPOSE: Procedure that retrieves the start and end line where the arrays are
  --           different in order to reduce the problem set
  -- =================================================================================
  PROCEDURE get_start_end_lines(old_array_i          IN t_varchar2_array,
                                new_array_i          IN t_varchar2_array,
                                start_line_o         OUT NUMBER,
                                end_line_old_o       OUT NUMBER,
                                end_line_new_o       OUT NUMBER,
                                differences_array_io IN OUT NOCOPY t_differences_array) IS
  BEGIN
    --------------------------
    -- Initialize variables --
    --------------------------
    start_line_o   := 1;
    end_line_old_o := old_array_i.count;
    end_line_new_o := new_array_i.count;
    -------------------------------------------------------
    -- Get first line where arrays are different         --
    -- Populate Diff Array with the first matching lines --
    -------------------------------------------------------
    WHILE start_line_o <= end_line_old_o
          AND start_line_o <= end_line_new_o
          AND (old_array_i(start_line_o) = new_array_i(start_line_o) OR
          (old_array_i(start_line_o) IS NULL AND new_array_i(start_line_o) IS NULL))
    LOOP
      differences_array_io.extend;
--      differences_array_io(differences_array_io.last) := t_differences(start_line_o,
--                                                                       old_array_i(start_line_o),
--                                                                       '========',
--                                                                       start_line_o,
--                                                                       new_array_i(start_line_o));
      differences_array_io(differences_array_io.last).old_line_number := start_line_o;
      differences_array_io(differences_array_io.last).old_file        := old_array_i(start_line_o);
      differences_array_io(differences_array_io.last).status          :=  '========';
      differences_array_io(differences_array_io.last).new_line_number := start_line_o;
      differences_array_io(differences_array_io.last).new_file        := new_array_i(start_line_o);
      start_line_o := start_line_o + 1;
    END LOOP;
    ------------------------------------------------------
    -- Get the end lines untillthe arrays are different --
    ------------------------------------------------------
    WHILE start_line_o <= end_line_old_o
          AND start_line_o <= end_line_new_o
          AND (old_array_i(end_line_old_o) = new_array_i(end_line_new_o) OR
          (old_array_i(end_line_old_o) IS NULL AND new_array_i(end_line_new_o) IS NULL))
    LOOP
      end_line_old_o := end_line_old_o - 1;
      end_line_new_o := end_line_new_o - 1;
    END LOOP;
  END get_start_end_lines;
  -- =================================================================================
  --  NAME:    INITIALIZE_MATRIX
  --  PURPOSE: Procedure that inicializes the Longest Common Subsequence (LCS) Matrix
  -- =================================================================================
  PROCEDURE initialize_matrix(matrix_i       IN OUT NOCOPY t_bidimensional_number_array,
                              start_line_i   IN NUMBER,
                              end_line_old_i IN NUMBER,
                              end_line_new_i IN NUMBER) IS
  BEGIN
    ----------------------------------------------------------------------
    -- Since LCS Matrix starts with zero and Oracle arrays start with 1 --
    -- we need to loop through all different old lines plus 1           --
    ----------------------------------------------------------------------
    FOR i IN 1 .. (end_line_old_i - start_line_i + 1) + 1
    LOOP
      ----------------------------------
      -- Extend two-dimensional array --
      ----------------------------------
      matrix_i.extend;
      ---------------------------------------
      -- initialize second dimention array --
      ---------------------------------------
      matrix_i(i) := t_number_array();
      ----------------------------------------------------------------------
      -- Since LCS Matrix starts with zero and Oracle arrays start with 1 --
      -- we need to loop through all different new lines plus 1           --
      ----------------------------------------------------------------------
      FOR j IN 1 .. (end_line_new_i - start_line_i + 1) + 1
      LOOP
        -----------------------------------------------------------------------
        -- Extend second dimension array (this extends first dimension only) --
        -----------------------------------------------------------------------
        matrix_i(i).extend;
        ----------------------------------------------
        -- If field is in first row or first column --
        ----------------------------------------------
        IF i = 1
           OR j = 1 THEN
          ------------------------
          -- Populate with zero --
          ------------------------
          matrix_i(i)(j) := 0;
        END IF;
      END LOOP;
    END LOOP;
  END initialize_matrix;
  -- =================================================================================
  --  NAME:    POPULATE_MATRIX
  --  PURPOSE: Procedure that populates LCS Matrix
  -- =================================================================================
  PROCEDURE populate_matrix(matrix_i       IN OUT NOCOPY t_bidimensional_number_array,
                            old_array_i    IN t_varchar2_array,
                            new_array_i    IN t_varchar2_array,
                            start_line_i   IN NUMBER,
                            end_line_old_i IN NUMBER,
                            end_line_new_i IN NUMBER) IS
  BEGIN
    ----------------------------------------------------
    -- Loop through all Matrix elements               --
    -- The loop starts at 2 since the first column is --
    -- already populated                              --
    ----------------------------------------------------
    FOR i IN 2 .. (end_line_old_i - start_line_i + 1) + 1
    LOOP
      FOR j IN 2 .. (end_line_new_i - start_line_i + 1) + 1
      LOOP
        -----------------------------------------------
        -- Populate LCS array based on LCS algorithm --
        -----------------------------------------------
        IF old_array_i(i - 1) = new_array_i(j - 1) THEN
          matrix_i(i)(j) := matrix_i(i - 1) (j - 1) + 1;
        ELSE
          matrix_i(i)(j) := greatest(matrix_i(i) (j - 1), matrix_i(i - 1) (j));
        END IF;
      END LOOP;
    END LOOP;
  END populate_matrix;
  -- =================================================================================
  --  NAME:    get_best_reading_plan
  --  PURPOSE: Procedure that populates the Diff Array based on the LCS Matrix
  -- =================================================================================
  PROCEDURE get_lcs_length(matrix_i       IN t_bidimensional_number_array,
                           old_array_i    IN t_varchar2_array,
                           new_array_i    IN t_varchar2_array,
                           i              IN NUMBER,
                           j              IN NUMBER,
                           start_line_i   IN NUMBER,
                           end_line_old_i IN NUMBER,
                           end_line_new_i IN NUMBER,
                           reading_type_i IN NUMBER,
                           lcs_length_o   IN OUT NUMBER) IS
  BEGIN
    -------------------------------------------------------------
    -- If iteraters are greater than zero and the arrays match --
    -------------------------------------------------------------
    IF i > 0
       AND j > 0
       AND (old_array_i(i + start_line_i - 1) = new_array_i(j + start_line_i - 1) OR
       (old_array_i(i + start_line_i - 1) IS NULL AND new_array_i(j + start_line_i - 1) IS NULL)) THEN
      --
      lcs_length_o := lcs_length_o + 1;
      ------------------------------------------------------
      -- Call get_differences for previous Matrix element --
      ------------------------------------------------------
      get_lcs_length(matrix_i       => matrix_i,
                     old_array_i    => old_array_i,
                     new_array_i    => new_array_i,
                     i              => i - 1,
                     j              => j - 1,
                     start_line_i   => start_line_i,
                     end_line_old_i => end_line_old_i,
                     end_line_new_i => end_line_new_i,
                     reading_type_i => reading_type_i,
                     lcs_length_o   => lcs_length_o);
    ELSE
      IF j > 0
         AND ((reading_type_i = 1 AND (i = 0 OR matrix_i(i + 1) (j) >= matrix_i(i) (j + 1))) OR
         (reading_type_i = 2 AND (i = 0 OR matrix_i(i + 1) (j) > matrix_i(i) (j + 1)))) THEN
        ------------------------------------------------------
        -- Call get_differences for previous Matrix element --
        ------------------------------------------------------
        get_lcs_length(matrix_i       => matrix_i,
                       old_array_i    => old_array_i,
                       new_array_i    => new_array_i,
                       i              => i,
                       j              => j - 1,
                       start_line_i   => start_line_i,
                       end_line_old_i => end_line_old_i,
                       end_line_new_i => end_line_new_i,
                       reading_type_i => reading_type_i,
                       lcs_length_o   => lcs_length_o);
      ELSIF i > 0
            AND ((reading_type_i = 1 AND (j = 0 OR matrix_i(i + 1) (j) < matrix_i(i) (j + 1))) OR
            (reading_type_i = 2 AND (j = 0 OR matrix_i(i + 1) (j) <= matrix_i(i) (j + 1)))) THEN
        ------------------------------------------------------
        -- Call get_differences for previous Matrix element --
        ------------------------------------------------------
        get_lcs_length(matrix_i       => matrix_i,
                       old_array_i    => old_array_i,
                       new_array_i    => new_array_i,
                       i              => i - 1,
                       j              => j,
                       start_line_i   => start_line_i,
                       end_line_old_i => end_line_old_i,
                       end_line_new_i => end_line_new_i,
                       reading_type_i => reading_type_i,
                       lcs_length_o   => lcs_length_o);
      END IF;
    END IF;
  END get_lcs_length;
  -- =================================================================================
  --  NAME:    GET_DIFFERENCES
  --  PURPOSE: Procedure that populates the Diff Array based on the LCS Matrix
  -- =================================================================================
  PROCEDURE get_differences(matrix_i                   IN t_bidimensional_number_array,
                            old_array_i                IN t_varchar2_array,
                            new_array_i                IN t_varchar2_array,
                            i                          IN NUMBER,
                            j                          IN NUMBER,
                            start_line_i               IN NUMBER,
                            end_line_old_i             IN NUMBER,
                            end_line_new_i             IN NUMBER,
                            reading_type_i             IN NUMBER,
                            last_populated_old_line_io IN OUT NUMBER,
                            last_populated_new_line_io IN OUT NUMBER,
                            differences_array_io       IN OUT NOCOPY t_differences_array) IS
  BEGIN
    -------------------------------------------------------------
    -- If iteraters are greater than zero and the arrays match --
    -------------------------------------------------------------
    IF i > 0
       AND j > 0
       AND (old_array_i(i + start_line_i - 1) = new_array_i(j + start_line_i - 1) OR
       (old_array_i(i + start_line_i - 1) IS NULL AND new_array_i(j + start_line_i - 1) IS NULL)) THEN
      ------------------------------------------------------
      -- Call get_differences for previous Matrix element --
      ------------------------------------------------------
      get_differences(matrix_i                   => matrix_i,
                      old_array_i                => old_array_i,
                      new_array_i                => new_array_i,
                      i                          => i - 1,
                      j                          => j - 1,
                      start_line_i               => start_line_i,
                      end_line_old_i             => end_line_old_i,
                      end_line_new_i             => end_line_new_i,
                      reading_type_i             => reading_type_i,
                      last_populated_old_line_io => last_populated_old_line_io,
                      last_populated_new_line_io => last_populated_new_line_io,
                      differences_array_io       => differences_array_io);
      -------------------------
      -- Populate Diff Array --
      -------------------------
      differences_array_io.extend;
--      differences_array_io(differences_array_io.last) := t_differences(i + start_line_i - 1,
--                                                                       old_array_i(i + start_line_i - 1),
--                                                                       '========',
--                                                                       j + start_line_i - 1,
--                                                                       new_array_i(j + start_line_i - 1));
      differences_array_io(differences_array_io.last).old_line_number := i + start_line_i - 1;
      differences_array_io(differences_array_io.last).old_file        := old_array_i(i + start_line_i - 1);
      differences_array_io(differences_array_io.last).status          :=  '========';
      differences_array_io(differences_array_io.last).new_line_number := j + start_line_i - 1;
      differences_array_io(differences_array_io.last).new_file        := new_array_i(j + start_line_i - 1);
      -----------------------------------------
      -- Reset last populated line variables --
      -----------------------------------------
      last_populated_old_line_io := NULL;
      last_populated_new_line_io := NULL;
    ELSE
      IF j > 0
         AND ((reading_type_i = 1 AND (i = 0 OR matrix_i(i + 1) (j) >= matrix_i(i) (j + 1))) OR
         (reading_type_i = 2 AND (i = 0 OR matrix_i(i + 1) (j) > matrix_i(i) (j + 1)))) THEN
        ------------------------------------------------------
        -- Call get_differences for previous Matrix element --
        ------------------------------------------------------
        get_differences(matrix_i                   => matrix_i,
                        old_array_i                => old_array_i,
                        new_array_i                => new_array_i,
                        i                          => i,
                        j                          => j - 1,
                        start_line_i               => start_line_i,
                        end_line_old_i             => end_line_old_i,
                        end_line_new_i             => end_line_new_i,
                        reading_type_i             => reading_type_i,
                        last_populated_old_line_io => last_populated_old_line_io,
                        last_populated_new_line_io => last_populated_new_line_io,
                        differences_array_io       => differences_array_io);
        ---------------------------------------------------------
        -- Start populating the differences from the same line --
        ---------------------------------------------------------
        IF last_populated_old_line_io IS NOT NULL THEN
          differences_array_io(last_populated_old_line_io).new_line_number := j + start_line_i - 1;
          differences_array_io(last_populated_old_line_io).new_file := new_array_i(j + start_line_i - 1);
          last_populated_old_line_io := last_populated_old_line_io + 1;
          ---------------------------------------------------
          -- Prevent populating a non extended array line  --
          ---------------------------------------------------
          IF last_populated_old_line_io > differences_array_io.count THEN
            last_populated_old_line_io := NULL;
          END IF;
        ELSE
          -------------------------
          -- Populate Diff Array --
          -------------------------
          differences_array_io.extend;
--          differences_array_io(differences_array_io.last) := t_differences(NULL,
--                                                                           NULL,
--                                                                           '<<<<>>>>',
--                                                                           j + start_line_i - 1,
--                                                                           new_array_i(j + start_line_i - 1));
      differences_array_io(differences_array_io.last).old_line_number := NULL;
      differences_array_io(differences_array_io.last).old_file        := NULL;
      differences_array_io(differences_array_io.last).status          :=  '<<<<>>>>';
      differences_array_io(differences_array_io.last).new_line_number := j + start_line_i - 1;
      differences_array_io(differences_array_io.last).new_file        := new_array_i(j + start_line_i - 1);
          IF last_populated_new_line_io IS NULL THEN
            last_populated_new_line_io := differences_array_io.last;
          END IF;
        END IF;
      ELSIF i > 0
            AND ((reading_type_i = 1 AND (j = 0 OR matrix_i(i + 1) (j) < matrix_i(i) (j + 1))) OR
            (reading_type_i = 2 AND (j = 0 OR matrix_i(i + 1) (j) <= matrix_i(i) (j + 1)))) THEN
        ------------------------------------------------------
        -- Call get_differences for previous Matrix element --
        ------------------------------------------------------
        get_differences(matrix_i                   => matrix_i,
                        old_array_i                => old_array_i,
                        new_array_i                => new_array_i,
                        i                          => i - 1,
                        j                          => j,
                        start_line_i               => start_line_i,
                        end_line_old_i             => end_line_old_i,
                        end_line_new_i             => end_line_new_i,
                        reading_type_i             => reading_type_i,
                        last_populated_old_line_io => last_populated_old_line_io,
                        last_populated_new_line_io => last_populated_new_line_io,
                        differences_array_io       => differences_array_io);
        ---------------------------------------------------------
        -- Start populating the differences from the same line --
        ---------------------------------------------------------
        IF last_populated_new_line_io IS NOT NULL THEN
          differences_array_io(last_populated_new_line_io).old_line_number := i + start_line_i - 1;
          differences_array_io(last_populated_new_line_io).old_file := old_array_i(i + start_line_i - 1);
          last_populated_new_line_io := last_populated_new_line_io + 1;
          ---------------------------------------------------
          -- Prevent populating a non extended array line  --
          ---------------------------------------------------
          IF last_populated_new_line_io > differences_array_io.count THEN
            last_populated_new_line_io := NULL;
          END IF;
        ELSE
          -------------------------
          -- Populate Diff Array --
          -------------------------
          differences_array_io.extend;
--          differences_array_io(differences_array_io.last) := t_differences(i + start_line_i - 1,
--                                                                           old_array_i(i + start_line_i - 1),
--                                                                           '<<<<>>>>',
--                                                                           NULL,
--                                                                           NULL);
      differences_array_io(differences_array_io.last).old_line_number := i + start_line_i - 1;
      differences_array_io(differences_array_io.last).old_file        := old_array_i(i + start_line_i - 1);
      differences_array_io(differences_array_io.last).status          :=  '<<<<>>>>';
      differences_array_io(differences_array_io.last).new_line_number := NULL;
      differences_array_io(differences_array_io.last).new_file        := NULL;
          ----------------------------------------------------------
          -- If the last populated parameter is not yet populated --
          ----------------------------------------------------------
          IF last_populated_old_line_io IS NULL THEN
            --------------------------------------------
            -- Save the next old line to be populated --
            --------------------------------------------
            last_populated_old_line_io := differences_array_io.last;
          END IF;
        END IF;
      END IF;
    END IF;
  END get_differences;
  -- =================================================================================
  --  NAME:    POPULATE_DIFF_LAST_LINES
  --  PURPOSE: Procedure that populates the Diff Array with the last matching lines
  -- =================================================================================
  PROCEDURE populate_diff_last_lines(old_array_i          IN t_varchar2_array,
                                     new_array_i          IN t_varchar2_array,
                                     end_line_old_i       IN NUMBER,
                                     end_line_new_i       IN NUMBER,
                                     differences_array_io IN OUT NOCOPY t_differences_array) IS
    -- Local Variables
    l_end_line_old NUMBER := end_line_old_i + 1;
    l_end_line_new NUMBER := end_line_new_i + 1;
  BEGIN
    -------------------------------------------
    -- Loop through all last matching lines  --
    -------------------------------------------
    FOR i IN 1 .. old_array_i.count - end_line_old_i
    LOOP
      --------------------------
      -- Populate Diff Array  --
      --------------------------
      differences_array_io.extend;
--      differences_array_io(differences_array_io.last) := t_differences(l_end_line_old,
--                                                                       old_array_i(l_end_line_old),
--                                                                       '========',
--                                                                       l_end_line_new,
--                                                                       new_array_i(l_end_line_new));
      differences_array_io(differences_array_io.last).old_line_number := l_end_line_old;
      differences_array_io(differences_array_io.last).old_file        := old_array_i(l_end_line_old);
      differences_array_io(differences_array_io.last).status          :=  '========';
      differences_array_io(differences_array_io.last).new_line_number := l_end_line_new;
      differences_array_io(differences_array_io.last).new_file        := new_array_i(l_end_line_new);
      --------------------------
      -- Increment Variables  --
      --------------------------
      l_end_line_old := l_end_line_old + 1;
      l_end_line_new := l_end_line_new + 1;
    END LOOP;
  END populate_diff_last_lines;
  -- =================================================================================
  --  NAME:    COMPARE_LINE_BY_LINE
  --  PURPOSE: Function that retrieves two CLOBs and outputs an array with the
  --           differences between them (line by line)
  -- =================================================================================
  FUNCTION compare_line_by_line(old_file_i IN CLOB,
                                new_file_i IN CLOB) RETURN t_differences_array IS
    -- Local Variables
    l_old_file_array          t_varchar2_array;
    l_new_file_array          t_varchar2_array;
    l_old_file_array_hashed   t_varchar2_array;
    l_new_file_array_hashed   t_varchar2_array;
    l_start_line              NUMBER;
    l_end_line_old            NUMBER;
    l_end_line_new            NUMBER;
    l_last_populated_old_line NUMBER;
    l_last_populated_new_line NUMBER;
    l_lcs_length_type1        NUMBER;
    l_lcs_length_type2        NUMBER;
    l_matrix                  t_bidimensional_number_array := NEW t_bidimensional_number_array();
    l_differences_array       t_differences_array := NEW t_differences_array();
  BEGIN
    ---------------------------------
    -- Transform Clobs into Arrays --
    ---------------------------------
    l_old_file_array := clob_to_array(old_file_i);
    l_new_file_array := clob_to_array(new_file_i);
    -----------------
    -- Hash Arrays --
    -----------------
--    SELECT dbms_utility.get_hash_value(column_value, 2, 1048576) BULK COLLECT
--      INTO l_old_file_array_hashed
--      FROM TABLE(l_old_file_array);
l_old_file_array_hashed := t_varchar2_array();
l_old_file_array_hashed.extend(l_old_file_array.COUNT);
    FOR i in 1 .. l_old_file_array.COUNT LOOP
      l_old_file_array_hashed(i) := dbms_utility.get_hash_value(l_old_file_array(i), 2, 1048576);
    END LOOP;
    -----------------
    -- Hash Arrays --
    -----------------
l_new_file_array_hashed := t_varchar2_array();
l_new_file_array_hashed.extend(l_new_file_array.COUNT);
--    SELECT dbms_utility.l_new_file_array(column_value, 2, 1048576) BULK COLLECT
--      INTO l_new_file_array_hashed
--      FROM TABLE(l_new_file_array);
    FOR i in 1 .. l_new_file_array.COUNT LOOP
      l_new_file_array_hashed(i) := dbms_utility.get_hash_value(l_new_file_array(i), 2, 1048576);
    END LOOP;
    ------------------------------------------------------
    -- Get Start and End Line of Differences            --
    -- Populate de Diff Array with Start Matching Lines --
    ------------------------------------------------------
    get_start_end_lines(old_array_i          => l_old_file_array,
                        new_array_i          => l_new_file_array,
                        start_line_o         => l_start_line,
                        end_line_old_o       => l_end_line_old,
                        end_line_new_o       => l_end_line_new,
                        differences_array_io => l_differences_array);
    ---------------------------
    -- Inicialize LCS Matrix --
    ---------------------------
    initialize_matrix(matrix_i       => l_matrix,
                      start_line_i   => l_start_line,
                      end_line_old_i => l_end_line_old,
                      end_line_new_i => l_end_line_new);
    -------------------------
    -- Populate LCS Matrix --
    -------------------------
    populate_matrix(matrix_i       => l_matrix,
                    old_array_i    => l_old_file_array_hashed,
                    new_array_i    => l_new_file_array_hashed,
                    start_line_i   => l_start_line,
                    end_line_old_i => l_end_line_old,
                    end_line_new_i => l_end_line_new);
    ---------------------------------------
    -- Get LCS Length for Reading Type 1 --
    ---------------------------------------
    l_lcs_length_type1 := 0;
    --
    get_lcs_length(matrix_i       => l_matrix,
                   old_array_i    => l_old_file_array,
                   new_array_i    => l_new_file_array,
                   i              => l_end_line_old - l_start_line + 1,
                   j              => l_end_line_new - l_start_line + 1,
                   start_line_i   => l_start_line,
                   end_line_old_i => l_end_line_old,
                   end_line_new_i => l_end_line_new,
                   reading_type_i => 1,
                   lcs_length_o   => l_lcs_length_type1);
    ---------------------------------------
    -- Get LCS Length for Reading Type 2 --
    ---------------------------------------
    l_lcs_length_type2 := 0;
    --
    get_lcs_length(matrix_i       => l_matrix,
                   old_array_i    => l_old_file_array,
                   new_array_i    => l_new_file_array,
                   i              => l_end_line_old - l_start_line + 1,
                   j              => l_end_line_new - l_start_line + 1,
                   start_line_i   => l_start_line,
                   end_line_old_i => l_end_line_old,
                   end_line_new_i => l_end_line_new,
                   reading_type_i => 2,
                   lcs_length_o   => l_lcs_length_type2);
    ---------------------------------------------
    -- Populate Diff Array Based on LCS Matrix --
    ---------------------------------------------
    get_differences(matrix_i                   => l_matrix,
                    old_array_i                => l_old_file_array,
                    new_array_i                => l_new_file_array,
                    i                          => l_end_line_old - l_start_line + 1,
                    j                          => l_end_line_new - l_start_line + 1,
                    start_line_i               => l_start_line,
                    end_line_old_i             => l_end_line_old,
                    end_line_new_i             => l_end_line_new,
                    reading_type_i             => CASE
                                                    WHEN l_lcs_length_type1 >= l_lcs_length_type2 THEN
                                                     1
                                                    ELSE
                                                     2
                                                  END,
                    last_populated_old_line_io => l_last_populated_old_line,
                    last_populated_new_line_io => l_last_populated_new_line,
                    differences_array_io       => l_differences_array);
    --------------------------------------------
    -- Populate Diff Array End Matching Lines --
    --------------------------------------------
    populate_diff_last_lines(old_array_i          => l_old_file_array,
                             new_array_i          => l_new_file_array,
                             end_line_old_i       => l_end_line_old,
                             end_line_new_i       => l_end_line_new,
                             differences_array_io => l_differences_array);
    --
    RETURN l_differences_array;
  END compare_line_by_line;

    FUNCTION compare_line_by_line_PIPE(old_file_i IN CLOB,
                                      new_file_i IN CLOB) RETURN t_differences_array PIPELINED
    IS
    l_differences_array t_differences_array;
    BEGIN

    l_differences_array := compare_line_by_line(old_file_i => old_file_i, new_file_i => new_file_i);

        FOR i in l_differences_array.FIRST .. l_differences_array.LAST LOOP
        PIPE ROW (l_differences_array(i));
        END LOOP;
        return;
    END;

  -- =================================================================================
  --  NAME:    COMPARE_LINE_BY_LINE_REFCURSOR
  --  PURPOSE: Function that retrieves two CLOBs and outputs a SYS_REFCURSOR with the
  --           differences between them (line by line)
  -- =================================================================================
  FUNCTION compare_line_by_line_refcursor(old_file_i IN CLOB,
                                          new_file_i IN CLOB) RETURN SYS_REFCURSOR IS
    -- Local Variables
    l_cursor            SYS_REFCURSOR;
    l_differences_array t_differences_array;
  BEGIN
    --------------------------------
    -- Get Differences into Array --
    --------------------------------
    l_differences_array := compare_line_by_line(old_file_i => old_file_i, new_file_i => new_file_i);
    -------------------------------------
    -- Open Cursor based on Diff Array --
    -------------------------------------
--    OPEN l_cursor FOR
--      SELECT *
--        FROM TABLE(l_differences_array);
    --
    RETURN l_cursor;
  END compare_line_by_line_refcursor;

END clob_compare;
/
