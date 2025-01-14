## vi editor
https://www.cs.colostate.edu/helpdocs/vi.html
vi <filename_NEW> or <filename_EXISTING>
### Editing commands
You should be in the "command mode" to execute these commands
```
i - Insert at cursor (goes into insert mode)
a - Write after cursor (goes into insert mode)
A - Write at the end of line (goes into insert mode)
ESC - Terminate insert mode (goes into command mode)
u - Undo last change
U - Undo all changes to the entire line
o - Open a new line (goes into insert mode)
dd - Delete line
3dd - Delete 3 lines.
D - Delete contents of line after the cursor
C - Delete contents of a line after the cursor and insert new text. Press ESC key to end insertion.
dw - Delete word
4dw - Delete 4 words
cw - Change word
x - Delete character at the cursor
r - Replace character
R - Overwrite characters from cursor onward
s - Substitute one character under cursor continue to insert
S - Substitute entire line and begin to insert at the beginning of the line
~ - Change case of individual character
```
### Moving within a file
```
k - Move cursor up
j - Move cursor down
h - Move cursor left
l - Move cursor right
0 - Move to start of current line
$ - Move to end of current line
w - Move to beginning of next word
:0<return> or 1G - Move to first line in file
:n<return> or nG - Move to line n
:$<return> or G - Move to last line
```
You can also use the arrow keys on the keyboard
### Determining Line Numbers
```
:.= <return> - Line number of current line at bottom of screen
:=<return> - Total number of lines at bottom of screen
^g<return> - Current line number, along with the total number of lines
```
### Saving and Closing the file
```
Shift+zz - Save the file and quit
:r filename<return> - Read the file and insert after current line
:12,35w smallfile<return> - Write the contents of the lines numbered 12 through 35 to a new file named smallfile
:w<return> - Save the file but keep it open
:w filename<return> - Save to another file
:q<return> - Quit without saving
:q!<return> - Quit without saving even though latest changes have not been saved
:wq<return> - Save the file and quit
:x<return> - Save the file and quit
```
