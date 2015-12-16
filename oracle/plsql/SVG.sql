create or replace package ojo_ora_gr as
procedure init_graph (  title   in     varchar2 := null,
      subtit  in     varchar2 := null,
       h    in     number := 720,
      w       in     number := 1280,
      legende in     boolean := false ) ;
procedure end_graph ;
end ojo_ora_gr;
/


create or replace package body ojo_ora_gr as
-- Private procedures and functions
 function std_head( title  in varchar2 := null,
     stitle  in varchar2 := null,
     h   in number := 720,
     w   in number := 1280 )return varchar2 is
ret varchar2(32767);
 begin
  ret := '<?xml version="1.0"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns:xlink="http://www.w3.org/1999/xlink" height="'||h||'" width="'||w||'" xmlns="http://www.w3.org/2000/svg">
<style type="text/css"> 
  #canvas rect { fill:#FFFFCC }
  #canvas line { stroke:#000000 }
  #T0 text { fill:#000000 ; font-size:16px ; text-anchor:middle }
  #T1 text { fill:#0F0F0F ; font-size:12px ; text-anchor:middle }  
</style>';
 if title is not null
 then
  ret:=ret||'
<text x="'||to_char(w/2)||'" y="20" id="T0">'||title||'</text>';
 end if ;
 if stitle is not null
 then
  ret:=ret||'
<text x="'||to_char(w/2)||'" y="35" id="T1">'||stitle||'</text>';
 end if ;
 return ret;
 end std_head;
 
 function line ( xd    in number ,
     yd       in number ,
     xf       in number ,
     yf       in number , 
     classe     in varchar2 := null ,
     id       in varchar2 := null) return varchar is
 PCL varchar2(255) := null;
 PID varchar2(255) := null;
 begin
  if classe is not null then
   PCL:='class="'||classe||'" ';
  end if;
  if id is not null then
   PID:='id="'||id||'"';
  end if;
  
  return '<line x1="'||xd||'" y1="'||yd||'" x2="'||xf||'" y2="'||yf||'" '||PCL||PID||'/>';
 end line;
 
 function rect ( x   in number ,
     y   in number ,
     h   in number ,
     w   in number , 
     classe  in varchar2 := null ,
     id   in varchar2 := null) return varchar is
 PCL varchar2(255) := null;
 PID varchar2(255) := null;
 begin
  if classe is not null then
   PCL:='class="'||classe||'" ';
  end if;
  if id is not null then
   PID:='id="'||id||'"';
  end if;
  
  return '<rect x="'||x||'" y="'||y||'" height="'||h||'" width="'||w||'" '||PCL||PID||'/>';
 end rect;

 function std_foot ( h in number := 720,
      w in number := 1280 )return varchar2 is
 begin
 return '<text x="'||to_char(w-5)||'" y="'||to_char(h-10)||'" style="fill:#0F0F0F;font-size:12px;text-anchor:end;">OJO-2010</text>
</svg>' ;
 end std_foot;
 
 function draw_gr_canvas ( h  in number ,
        w     in number ,
        legende  in boolean ,
        id     in varchar2 := 'canvas') return varchar2 is
 dh number;
 begin
  if legende
  then
   dh:=320;
  else
   dh:=150;
  end if;
  
  return '<g id="canvas">
  '||rect(100,50,h-dh,w-280,null)||'
  '||line(100,50,100,55+(h-dh))||'
  '||line(95,51+(h-dh),w-180,51+(h-dh))||'
</g>';
 end draw_gr_canvas;
 
-- Public procedures and functions
 
 procedure init_graph ( title   in     varchar2 := null,
      subtit  in     varchar2 := null,
      h    in     number := 720,
      w       in     number := 1280,
      legende in     boolean := false ) is
 begin
  dbms_output.enable('20000000');
  dbms_output.put_line(std_head(title,subtit,h,w));
  dbms_output.put_line(draw_gr_canvas(h,w,legende));
 end init_graph;
 
 procedure end_graph is
 begin
  dbms_output.put_line(std_foot);
 end end_graph;

end ojo_ora_gr;
/
