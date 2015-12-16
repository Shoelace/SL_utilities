/*
* Online - a quick listing of logged on friends
*
* Original Authors: Entity , Shoe Lace
*
* website http://online.sourceforge.net
*
* Copyright (C) 
*
* This program is free software; you can redistribute it and/or modify it
* under the terms of the GNU General Public License as published by the
* Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful, but WITHOUT ANY
* WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
* A PARTICULAR PURPOSE. See the GNU General Public License for more details.
* You should have received a copy of the GNU General Public License along with
* this program; if not, write to the
* 	Free Software Foundation, Inc.
* 	59 Temple Place, Suite 330,
*	Boston, MA 02111-1307 USA
*
*/
#include <stdio.h>
#include <utmpx.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <time.h>

#include <stdlib.h>
#include <string.h>


struct friends{
        char name[20];
        char nickname[40];
        int color;
        struct friends *next;
};

struct on{
	char name[20];
	char host[257];
	char line[20];
	int idle;
	struct on *next;
};

struct list{
	char name[20];
	char nickname[40];
	char host[20];
	int sessions;
	int color;
	int line;
	int idle;
	struct list *next;
};

typedef struct friends friends;
typedef struct on on;
typedef struct utmpx utmpx;
typedef struct list list;
typedef struct stat sta;

void init_queues();
void create_friend_list();
void create_on_list();
void create_list();
void insert_friend(friends *data);
void insert_on(on *data);
void insert_list(list *data);

void text_print_list(int the_time);

void create_widget(char *, int);

#define MAXFRIENDS 50

friends *friends_head;
on 	*on_head;
list 	*list_head;

static const char VERSION[32]={"ver 1.0 Shoe Lace ------------"};

int main(int argc, char *argv[], char *env[])
{
	time_t the_time;
	time(&the_time);

	init_queues();
	create_friend_list();
	create_on_list();
	create_list();

	text_print_list(the_time);

	return(EXIT_SUCCESS);
}

void create_friend_list(){
	FILE *friend;
	friends data;
	char home[255];
	char *friends_file;

	friends_file = getenv("FRIENDS");

	if (friends_file == NULL)
		sprintf(home, "%s/.friends", getenv("HOME"));
	else
		sprintf(home, "%s", friends_file);

        if((friend=fopen(home,"r")) == NULL){
                fprintf(stderr,"\n     Cannot access friends file \"%s\"",home);
                exit(1);
        }

	while((fscanf(friend, "%d %s %[^\n]", &data.color, data.name, data.nickname))!=EOF){
		if(strlen(data.nickname)>=30)
			data.nickname[30]='\0';
		insert_friend(&data);
	}

	fclose(friend);
}

void create_on_list(int the_time){
	utmpx *ut;
	on data;
	ut=(utmpx *)malloc(sizeof(utmpx));

      	while((ut=getutxent())!=NULL){
		if((ut->ut_type<=9)&&(ut->ut_type>=0)&&(ut->ut_type!=8)){
			strcpy(data.host, ut->ut_host);
			strcpy(data.name, ut->ut_user);
			strcpy(data.line, ut->ut_line);
        		insert_on(&data);
		}
	}
}

void insert_list(list *data){
	list *curr, *temp1;
	temp1=(list *)malloc(sizeof(list));

	strcpy(temp1->name, data->name);
	strcpy(temp1->nickname, data->nickname);
	strcpy(temp1->host, data->host);
	temp1->sessions=data->sessions;
	temp1->color=data->color;
	temp1->line=data->line;
	temp1->idle=data->idle;

        if(list_head==NULL){
                list_head=temp1;  
		temp1->next=NULL; 
        	return;
	}
        
	curr=list_head;
        
        while(curr->next!=NULL){
                curr=curr->next;
	}

        if(curr->next==NULL){
                curr->next=temp1;
		temp1->next=NULL;
	}
}

void insert_friend(friends *data){
	friends *curr, *temp1;
	temp1=(friends *)malloc(sizeof(friends));

	strcpy(temp1->name, data->name);
	strcpy(temp1->nickname, data->nickname);
	temp1->color=data->color;

        if(friends_head==NULL){
                friends_head=temp1;
		temp1->next=NULL;   
        	return;
	}
        
	curr=friends_head;
        
        while(curr->next!=NULL){
                curr=curr->next;
	}

        if(curr->next==NULL){
                curr->next=temp1;
		temp1->next=NULL;
	}
}

void insert_on(on *data)
{
	on *curr, *temp1;
	temp1=(on *)malloc(sizeof(on));

	strcpy(temp1->host, data->host);
	strcpy(temp1->name, data->name);
	strcpy(temp1->line, data->line);
	temp1->idle=data->idle;

        if(on_head==NULL){
                on_head=temp1;  
		temp1->next=NULL; 
        	return;
	}
        
	curr=on_head;
        
        while(curr->next!=NULL){
                curr=curr->next;
	}

        if(curr->next==NULL){
                curr->next=temp1;
		temp1->next=NULL;
	}
}

void init_queues(void)
{
        friends_head=NULL;
	on_head=NULL;
	list_head=NULL;
}

void text_print_list(int the_time)
{
	list *curr;
	int seconds;

        printf("     Login  idle open  Location            Name\n");
        printf("-------------------------------------------------------------------------------");
	if(list_head==NULL){
		printf("     You have no friends currently OnLine.  :p");
	}else{
		curr=list_head;
		while(curr!=NULL){
			seconds=(the_time-curr->idle)/60;
			if(seconds>60)
				seconds=60;

			switch(curr->color){
				case 1:
					printf("\033[0;40;32m");
					break;
				case 2:
					printf("\033[0;40;34m");
					break;
				case 3:
					printf("\033[0;40;33m");
					break;
				case 4:
					printf("\033[0;40;35m");
					break;
				default:
					printf("\033[0;40;31m");
					break;
			}

			if((curr->line==1)&&(seconds<=1)){
				printf("\033[1m");
				printf("\n%10s", curr->name); 
				printf("   --   %d", curr->sessions);
				printf("*");
                		printf("   %s", curr->host);
				printf("   %s", curr->nickname);   
        			printf("\033[0;40;37m");
			}else{
				printf("\n%10s", curr->name); 
				if(seconds>=1){
					printf("   %-2u",seconds);
				}else{
					printf("   --");
				}
				printf("   %d", curr->sessions);
                		printf("    %s", curr->host);
				printf("   %s", curr->nickname);   
        			printf("\033[0;40;37m");
			}
			curr=curr->next;
		}
        }
        printf("\n-- -=OnLine=- %s-----------------------------------\n", VERSION);
	return;
}

void create_list(){
	int sessions, line, newidle, oldidle, seconds;
	char dir[40], host[257];
	list data;
	friends *currf;
	on *curro;
	sta *st;
	st=(sta *)malloc(sizeof(sta));

	if(friends_head==NULL){
		printf("\n     Friend file is empty\n");
		exit;
	}
	if(on_head==NULL){
		printf("\n     Utmpx file is unaccessable\n");
		exit;
	}
	
	currf=friends_head;

	while(currf!=NULL){
		newidle=sessions=line=seconds=0;
		oldidle=-1;
		curro=on_head;
		while(curro!=NULL){
			if((strcmp(currf->name, curro->name))==0){
				if(sessions==0){
					strcpy(host, curro->host);
                  			if(strlen(host)<17){
						strncat(host,"                  ",17-strlen(host));
                  			}
                  			if(strlen(host)>=17){
                    				host[17]='\0';
                  			}
				}
#ifdef SOLARIS
				sprintf(dir,"/devices/pseudo/pts@0:%c%c%c", curro->line[4], curro->line[5], curro->line[6]);
#else
				sprintf(dir,"/dev/pts/%c%c%c", curro->line[4], curro->line[5], curro->line[6]);
#endif
                		stat(dir, st);
                		if((st->st_mode & S_IWGRP) ||(st->st_mode & S_IWOTH)){
                  			line=1;
                		}
				newidle=st->st_atime;

				if(oldidle==-1){
					oldidle=newidle;
				}else{
					if((newidle>oldidle)&&(newidle>=0)){
						oldidle=newidle;
					}
				}
				sessions++;
			}
			curro=curro->next;
		}
		if(sessions>0){
			strcpy(data.name, currf->name);
			strcpy(data.nickname, currf->nickname);
			strcpy(data.host, host);
			data.sessions=sessions;
			data.color=currf->color;
			data.line=line;
			data.idle=oldidle;
			insert_list(&data);
		}
		currf=currf->next;
	}
}
//END OF FILE

