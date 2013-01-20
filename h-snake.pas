{   H-SNAKE - author: Jakub "Horuss" Czajkowski
    language: Free Pascal
    IDE: Dev Pascal 1.9.2
	License: GNU GPL
}

PROGRAM h_snake;
USES crt;
TYPE
    coordinates=record
        x,y:byte;
    end;
CONST
    sizex=30; { size of gamearea }
    sizey=15;
    body='o';
    h='O';
    MAX=255; { max snake length }
VAR
    length,tail,head,next,time,bonus_stop:byte;   { MAX gives us chance to use byte }
    snake:array[1..MAX] of coordinates;                { snake == array of coordinate records, this snake is like queue implemented on array }
    gamearea:array[1..sizex+2,1..sizey+2] of char; 
    food,bonus:coordinates;
    crash,legal,eaten,ch_ok:boolean;
    klawisz,direction,ch_menu,ch_level,ch_diff:char;
    score:integer;

{ ********* DRAW LOGO ********** }
procedure logo;
begin
    gotoxy(1,1);
    textcolor(lightcyan);
    writeln(' _  _         ___   _  _     _     _  __  ___ ');
    writeln('| || |  __   / __| | \| |   /_\   | |/ / | __|');
    writeln('| __ | |__|  \__ \ | .` |  / _ \  |   <  | _| ');
    writeln('|_||_|       |___/ |_|\_| /_/ \_\ |_|\_\ |___|');
    writeln;
    textcolor(white);
end;

{ ********* INITIATIN ********** }
procedure init;              { clear score, draw snake on the starting position }
var i:byte;
begin
    score:=0;
    length:=5;
    gotoxy(41,7);
    write('Moving - Arrows');
    gotoxy(41,8);
    write('Exit   - ESC');
    gotoxy(41,9);
    write('Pause  - Spacebar');
    gotoxy(41,11);
    textcolor(yellow);
    write('length:  ',length:3);
    gotoxy(41,13);
    write('score:',score:6);
    textcolor(white);
    tail:=1;
    head:=length;
    direction:='r';
    crash:=false;
    for i:=1 to length do
    begin
        snake[i].x:=4+i-1;
        snake[i].y:=8;
        gotoxy(snake[i].x,8);
        textcolor(red);
        write(body);
    end;
    gotoxy(snake[length].x,snake[length].y);
    textcolor(lightred);
    write(h);
    textcolor(white);
    gotoxy(1,25);
end;

{ ********* SELECTING LEVEL ********** }
procedure select_level;                { different level == different obstacles }
var i:byte;
begin
    writeln;
    writeln(' Choose level:');
    writeln(' 1. Classic over all');
    writeln(' 2. Double sharp');
    writeln(' 3. Labirynth of madness');
    ch_level:=readkey;
    if (ch_level='1') or (ch_level='2') or (ch_level='3') then ch_ok:=true else ch_ok:=false; { is the choose valid }
    if ch_level='2' then
    begin
        for i:=5 to 9 do
            gamearea[5,i]:='|';
        for i:=6 to 11 do
            gamearea[i,5]:='-';
        for i:=10 to 13 do
            gamearea[15,i]:='|';
        for i:=20 to 25 do
            gamearea[i,5]:='-';
        for i:=5 to 9 do
            gamearea[26,i]:='|';
    end;
    if ch_level='3' then
    begin
        for i:=5 to 13 do
            gamearea[6,i]:='|';
        for i:=5 to 13 do
            gamearea[27,i]:='|';
        for i:=7 to 15 do
            gamearea[i,9]:='-';
        for i:=18 to 26 do
            gamearea[i,9]:='-';
        for i:=13 to 20 do
            gamearea[i,4]:='-';
        for i:=13 to 20 do
            gamearea[i,14]:='-';
    end;
end;

{ ********* SELECTING DIFFICULTY ********** }
procedure select_difficulty;                                         { changing delay of each snake "step" }
begin
    writeln;
    writeln(' Choose difficulty:');
    writeln(' 1. Easy - snake moves slowly.');
    writeln(' 2. Normal - snake moves normally.');
    writeln(' 3. Hard - snake moves fast.');
    ch_diff:=readkey;
    if (ch_diff='1') or (ch_diff='2') or (ch_diff='3') then ch_ok:=true else ch_ok:=false;     { is the choose valid }
    if ch_diff='1' then
    begin
        time:=200;
    end;
    if ch_diff='2' then
    begin
        time:=150;
    end;
    if ch_diff='3' then
    begin
        time:=70;
    end;
end;

{ ********* PRZYGOTOWANIE PLANSZY ********** }
procedure walls;                         { one-time paint walls }
var i:byte;
begin
    for i:=2 to sizex+1 do
    begin
        gamearea[i,1]:='-';
    end;
    for i:=2 to sizey+1 do
    begin
        gamearea[1,i]:='|';
    end;
    for i:=2 to sizey+1 do
    begin
        gamearea[sizex+2,i]:='|';
    end;
    for i:=2 to sizex+1 do
    begin
        gamearea[i,sizey+2]:='-';
    end;
    gamearea[1,sizey+2]:='+';
    gamearea[sizex+2,1]:='+';
    gamearea[1,1]:='+';
    gamearea[sizex+2,sizey+2]:='+';
end;

{ ********* CLEARING ********** }
procedure gamearea_clear;                                       { clearing after previous game }
var i,j:byte;
begin

    for i:=2 to sizey+1 do
        for j:=2 to sizex+1 do
            gamearea[j,i]:=' ';
end;

{ ********* DRAWING GAMEAREA ********** }
procedure gamearea_draw;                                        { painting gamearea: walls and obstacles }
var i,j:byte;
begin
    gotoxy(1,6);
    for i:=1 to sizey+2 do
    begin
        for j:=1 to sizex+2 do
        begin
            if (gamearea[j,i]='-') or (gamearea[j,i]='+') or (gamearea[j,i]='|') then
            begin
                textcolor(lightgray);
                textbackground(lightgray);
                write(gamearea[j,i]);
                textcolor(white);
                textbackground(black);
            end
            else
            begin
                write(gamearea[j,i]);
            end;
        end;
        writeln;
    end;
end;

{ ********* SCORE ********** }
procedure score_endgame;                                { after finishing shows your score }
begin
    if ch_diff='2' then score:=score*2;
    if ch_diff='3' then score:=score*4;
    if ch_level='2' then score:=score+20;
    if ch_level='3' then score:=score+50;
    clrscr;
    logo;
    writeln;
    textcolor(yellow);
    writeln(' Your snake length: ',length:3);
    writeln;
    writeln(' Your score:      ',score:6);
    writeln;
    writeln('    !!!    CONGRATULATIONS    !!!');
    textcolor(white);
    writeln;
    writeln;
    writeln(' Press ESC, to continue.');
    repeat until readkey=#27;
end;

{ ********* COLLISION CHECK ********** }
procedure check;                                                { checking collision with snake/walls/obstacles }
var i:byte;
begin
    if tail<head then
    begin
        for i:=tail to head-2 do
            if (snake[i].x=snake[head].x) and (snake[i].y=snake[head].y) then begin crash:=true end;             { snake itself }
    end
    else
    begin
        for i:=tail to MAX do                                                                               { snake itself if just passing the "snake" array }
            if (snake[i].x=snake[head].x) and (snake[i].y=snake[head].y) then begin crash:=true; end;
        for i:=2 to head-2 do
            if (snake[i].x=snake[head].x) and (snake[i].y=snake[head].y) then begin crash:=true; end;
    end;
    if (gamearea[snake[head].x,snake[head].y-5]='|') or (gamearea[snake[head].x,snake[head].y-5]='-') then begin crash:=true;end;        { wall/obstacle }
end;

{ ********* MOVE (1 step) ********** }
procedure move;
begin
    if head<MAX then next:=head+1
    else next:=1;
    if keypressed then
    begin
        klawisz:=readkey;
        if klawisz=#27 then begin crash:=true; end;           {exit}
        if klawisz=#32 then                                   {pause}
        begin
            gotoxy(41,17);
            write('PAUSE');
            gotoxy(1,25);
            repeat until readkey=#32;
            gotoxy(41,17);
            write('     ');
            gotoxy(1,25);
        end;
        if klawisz = #0 then       {arrow (sending 2 chars, first is #0)}
        begin
            legal:=false;
            klawisz:=readkey;
            case klawisz of
                #75:
                if direction<>'r' then
                begin
                    snake[next].x:=snake[head].x-1;
                    snake[next].y:=snake[head].y;
                    direction:='l';
                    legal:=true;
                end;
                #80:
                if direction<>'u' then
                begin
                    snake[next].x:=snake[head].x;
                    snake[next].y:=snake[head].y+1;
                    direction:='d';
                    legal:=true;
                end;
                #77:
                if direction<>'l' then
                begin
                    snake[next].x:=snake[head].x+1;
                    snake[next].y:=snake[head].y;
                    direction:='r';
                    legal:=true;
                end;
                #72:
                if direction<>'d' then
                begin
                    snake[next].x:=snake[head].x;
                    snake[next].y:=snake[head].y-1;
                    direction:='u';
                    legal:=true;
                end;
            end;
            if legal=true then
            begin
                if eaten=false then
                begin
                    gotoxy(snake[tail].x,snake[tail].y);
                    write(' ');
                    snake[tail].x:=0; snake[tail].y:=0;
                end;
                gotoxy(snake[head].x,snake[head].y);
                textcolor(red);
                write(body);
                textcolor(white);
                if eaten=false then
                begin
                    if tail<MAX then inc(tail)       { going through snake array }
                    else tail:=1;
                end;
                if head<MAX then inc(head)         { going through snake array }
                else head:=1;
                gotoxy(snake[head].x,snake[head].y);
                textcolor(lightred);
                write(h);
                textcolor(white);
                gotoxy(1,25);
                delay(time);
            end;
        end;
    end
    else                                          { if not keypressed, keeping old direction }
    begin
        if eaten=false then
        begin
            gotoxy(snake[tail].x,snake[tail].y);
            write(' ');
            snake[tail].x:=0; snake[tail].y:=0;
        end;
        gotoxy(snake[head].x,snake[head].y);
        textcolor(red);
        write(body);
        textcolor(white);
        case direction of
            'l':
            begin
                snake[next].x:=snake[head].x-1;
                snake[next].y:=snake[head].y;
            end;
            'd':
            begin
                snake[next].x:=snake[head].x;
                snake[next].y:=snake[head].y+1;
            end;
            'r':
            begin
                snake[next].x:=snake[head].x+1;
                snake[next].y:=snake[head].y;
            end;
            'u':
            begin
                snake[next].x:=snake[head].x;
                snake[next].y:=snake[head].y-1;
            end;
        end;
        if eaten=false then
        begin
            if tail<MAX then inc(tail)           { going through snake array }
            else tail:=1;
        end;
        if head<MAX then inc(head)             { going through snake array }
        else head:=1;
        gotoxy(snake[head].x,snake[head].y);
        textcolor(lightred);
        write(h);
        textcolor(white);
        gotoxy(1,25);
        delay(time);
    end;
    check;                                        { after move, check the collisions }
end;

{ ********* ADDIND FOOD ********** }
procedure add_food;
var possible:boolean;
    i:byte;
begin
    repeat
    begin
        possible:=true;
        food.x:=random(sizex)+2;
        food.y:=random(sizey)+7;
        if tail<head then
        for i:=tail to head do
        begin
            if (food.x=snake[i].x) and (food.y=snake[i].y) then possible:=false;         {checking if the food is "on" snake}
        end
        else
        begin
            for i:=tail to MAX do
                if (food.x=snake[i].x) and (food.y=snake[i].y) then possible:=false;
            for i:=1 to head do
                if (food.x=snake[i].x) and (food.y=snake[i].y) then possible:=false;
        end;
        if (gamearea[food.x,food.y-5]='|') or (gamearea[food.x,food.y-5]='-') then possible:=false;    {checking if the food is on wall/obstacle}
        if (abs(food.x-snake[head].x)<3) and (abs(food.y-snake[head].y)<3) then possible:=false;                 {checking if the food is not too close to snakes head}
    end;
    until (possible=true);
    gotoxy(food.x,food.y);
    textcolor(lightgreen);
    write('$');
    textcolor(white);
    gotoxy(1,25);
end;

{ ********* ADDING BONUS ********** }
procedure add_bonus;
var possible:boolean;
    i:byte;
begin
    repeat
    begin
        possible:=true;
        bonus.x:=random(sizex)+2;
        bonus.y:=random(sizey)+7;
        if tail<head then
        for i:=tail to head do
        begin
            if (bonus.x=snake[i].x) and (bonus.y=snake[i].y) then possible:=false;                {checking if the bonus is on snake}
        end
        else
        begin
            for i:=tail to MAX do
                if (bonus.x=snake[i].x) and (bonus.y=snake[i].y) then possible:=false;
            for i:=1 to head do
                if (bonus.x=snake[i].x) and (bonus.y=snake[i].y) then possible:=false;
        end;
        if (gamearea[bonus.x,bonus.y-5]='|') or (gamearea[bonus.x,bonus.y-5]='-') then possible:=false;         {checking if the bonus is on wall/obstacle}
        if (abs(bonus.x-snake[head].x)<3) and (abs(bonus.y-snake[head].y)<3) then possible:=false;                {checking if the bonus is not too close to snakes head}
    end;
    until (possible=true);
    gotoxy(bonus.x,bonus.y);
    textcolor(cyan);
    write('X');
    textcolor(white);
    gotoxy(1,25);
end;

{ ********* STARTING GAME ********** }
procedure play;
begin
    clrscr;
    logo;
    gamearea_draw;
    init;
    add_food;
    gotoxy(41,17);
    textcolor(lightcyan);
    write('Press any key, to continue');
    gotoxy(1,25);
    textcolor(white);
    repeat until keypressed;
    gotoxy(41,17);
    write('                                        ');
    repeat   {main game loop}
    begin
        if length=MAX then
        begin
            gotoxy(41,17);
            textcolor(lightred);
            write('MAXIMUM LENGTH');
            textcolor(white);
            crash:=true;
        end;
        eaten:=false;
        if (food.x=snake[head].x) and (food.y=snake[head].y) then 
        begin
            eaten:=true;
            inc(length);
            if length=bonus_stop then
            begin
                gotoxy(41,15);
                write('                           ');
                time:=time-50;
                bonus_stop:=0;
            end;
            add_food;
            if (random(8)=1) and (bonus.x=0) and (bonus.y=0) and (length-bonus_stop>0) then add_bonus;       
            gotoxy(50,11);
            textcolor(yellow);
            write(length:3);
            score:=score+10;
            gotoxy(47,13);
            write(score:6);
            textcolor(white);
        end;
        if (bonus.x=snake[head].x) and (bonus.y=snake[head].y) then
        begin
            bonus.x:=0;
            bonus.y:=0;
            time:=time+50;
            gotoxy(41,15);
            textcolor(lightgreen);
            write('Bonus - you are slowed!');
            textcolor(white);
            bonus_stop:=length+2;
            score:=score+20;
            gotoxy(47,13);
            textcolor(yellow);
            write(score:6);
            textcolor(white);
        end;
        move;
    end;
    until crash=true;
    gotoxy(41,17);
    textcolor(lightred);
    write('GAME OVER. Press ESC, to exit.');
    gotoxy(1,25);
    textcolor(white);
    repeat until readkey=#27;
    score_endgame;
end;

{ ********* HELP FROM MENU ********** }
procedure help;
begin
    clrscr;
    logo;
    writeln(' About the game:');
    writeln('       Your task is to control the snake and eat food.');
    writeln('       Avoid hitting yourself and the walls.');
    textcolor(lightgreen);
    write('       $');textcolor(white);writeln(' - food, increase length and your score by 10.');
    textcolor(cyan);
    write('       X');textcolor(white);writeln(' - bonus, reduces the speed of the snake for some time');
    writeln('           and increase your score by 20.');
    writeln('       Your score is also affected by selected level and difficulty.');
    writeln;
    writeln(' Controls:');
    writeln('       Control snake using arrows.');
    writeln('       Spacebar allows you to turn the pause on/off .');
    writeln;
    writeln;
    writeln(' Press ESC, to return.');
    repeat until readkey=#27;
end;

{ ********* ABOUT FROM MENU ********** }
procedure about;
begin
    clrscr;
    logo;
    writeln(' Author: Jakub "Horuss" Czajkowski.');
	writeln;
    writeln(' Game created during course "Fundamentals of Computer Science" on');
    writeln(' AGH University of Science and Technology in Cracow');
    writeln;
    writeln;
    writeln(' Press ESC, to return.');
    repeat until readkey=#27;
end;

{ ********* MENU ********** }
procedure menu;
begin
    if ch_menu='1' then
    begin
        select_level; 
        if ch_ok=true then select_difficulty;
        if ch_ok=true then play;
    end;
    if ch_menu='2' then help;
    if ch_menu='3' then about;
end;

{ ####################     PROGRAM     ######################  }
BEGIN
    textcolor(white);
    clrscr;
    randomize;
    walls;
    repeat
    begin
        gamearea_clear;
        clrscr;
        logo;
        writeln('  MENU:');
        writeln;
        writeln('   1.    Play !');
        writeln('   2.    Help');
        writeln('   3.    About');
        writeln('   ESC.  Exit');
        ch_menu:=readkey;
        menu;
    end;
    until ch_menu=#27;
END.
