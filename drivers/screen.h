//Defines functions for printing characters to screen, handling scrolling
//and handling the cursor

#include "../kernel/low-level.h"

#define VIDEO_ADDRESS 0xb8000
#define MAX_ROWS 25
#define MAX_COLS 80
#define WHITE_ON_BLACK 0x0f		//default colorscheme

//Screen device I/O ports
#define REG_SCREEN_CTRL 0x3D4
#define REG_SCREEN_DATA 0x3D5

/*
 * Memory copy
 */
void memory_copy(char* source, char* dest, int no_bytes)
{
	int i;
	for(i=0; i<no_bytes; i++)
		*(dest + i) = *(source + i);
}

/*
 * Offset functions
 */

int get_screen_offset(int col, int row)
{
	int offset = (row * MAX_COLS + col) * 2;
	
	return offset;
}

/*
 * Cursor functions
 */

int get_cursor()
{
	//The device uses control register as index to select internal registers
	//We are interested in:
	//	reg 14: high byte of the cursor's offset
	//	reg 15: low byte of the cursor's offset
	//When internal register is selected, we may read or write a byte on the data register
	
	port_byte_out(REG_SCREEN_CTRL, 14);
	int offset = port_byte_in(REG_SCREEN_DATA) << 8;
	port_byte_out(REG_SCREEN_CTRL, 15);
	offset += port_byte_in(REG_SCREEN_DATA);
	
	//Since cursor offset reported by VGA hardware is the num of characters, we multiply by two to convert to a character cell offset
	return offset * 2;
}

int set_cursor(int offset)
{
	offset /= 2;	//convert from cell offset to char offset
	
	//Write bytes to internal device registers
	port_byte_out(REG_SCREEN_CTRL, 14);
	port_byte_out(REG_SCREEN_DATA, (unsigned char)(offset >> 8));
	port_byte_out(REG_SCREEN_CTRL, 15);
	port_byte_out(REG_SCREEN_DATA, (unsigned char)(offset));
	
	//Return updated cursor position
	return offset;
}

/*
 * Screen srolling
 */
int handle_scrolling(int cursor_offset)
{
	//If the cursor is within the screen, return it unmodified
	if(cursor_offset < MAX_ROWS * MAX_COLS * 2)
		return cursor_offset;
	
	//Shuffle the rows back one
	int i;
	for(i=1; i<MAX_ROWS; i++)
	{
		memory_copy((char*)(get_screen_offset(0, i) + VIDEO_ADDRESS),
			(char*)(get_screen_offset(0, i-1) + VIDEO_ADDRESS),
			MAX_COLS*2);
	}
	
	//Blank the last line by setting all bytes to 0
	char* last_line = (char*)(get_screen_offset(0, MAX_ROWS-1) + VIDEO_ADDRESS);
	for(i=0; i<MAX_COLS*2; i++)
		last_line[i] = 0;
		
	//Move the offset back one row, such that it is now on the last row, rather than off the edge of the screen
	cursor_offset -= 2*MAX_COLS;
	
	//Return updated cursor position
	return cursor_offset;
}

/*
 * Print char function
 */

void print_char(char character, int col, int row, char attribute_byte)
{
	unsigned char* vidmem = (unsigned char*) VIDEO_ADDRESS;	//create byte pointer to start of video memory
	
	//If attribute byte is zero, assume default style
	if(!attribute_byte)
		attribute_byte = WHITE_ON_BLACK;
		
	//Get video memory offset for the screen location
	int offset;
	
	if(col >= 0 && row >= 0)
		offset = get_screen_offset(col, row);
	else
		offset = get_cursor();
	
	//Account for newline
	if(character == '\n')
	{
		//Set offset to end of row (will advance to next row in following instructions)
		int rows = offset / (2 * MAX_COLS);
		offset = get_screen_offset(79, rows);
	}
	else
	{
		//If no newline, write character and attribute byte to video memory at current offset
		vidmem[offset] = character;
		vidmem[offset+1] = attribute_byte;
	}
	
	//Update the offset to the next character cell (2 bytes ahead)
	offset += 2;
	
	//Make scrolling adjustment
	offset = handle_scrolling(offset);
	
	//Update cursor position
	set_cursor(offset);
}

/*
 * Printing convenience functions
 */

void word_wrap(char* message)
{
	//Iterate through the string searching for spaces
	for(int i=0, character=get_cursor(); message[i] != 0; i++, character+=2)
	{
		//If space is found
		if(message[i] == ' ')
		{
			//Calculate distance to the end of the word
			int word_end;
			for(word_end = 0; message[word_end + character] != 0 &&  message[word_end + character] != ' ' && message[word_end + character] != '\n'; word_end++);
			word_end += character;
			
			//Calculate distance to the end of the line
			//Set offset to end of row (will advance to next row in following instructions)
			int rows = character / (2 * MAX_COLS);
			int line_end = get_screen_offset(79, rows);
			
			//If distance to end of line < distance to end of word, break line
			if(word_end > line_end)
				message[i] = '\n';
		}		
	}
}

void print_at(char* message, int col, int row)
{
	//Update the cursor if col and row are not negative
	if(col >= 0 && row >= 0)
		set_cursor(get_screen_offset(col, row));
	
	//Loop through each char of the message and print it
	int i=0;
	while(message[i] !=0)
		print_char(message[i++], col, row, WHITE_ON_BLACK);
}

void print(char* message)
{
	word_wrap(message);
	print_at(message, -1, -1);
}

/*
 * Clear screen
 */
 
void clear_screen()
{
	int row = 0;
	int col = 0;
	
	//Loop through video memory and write blank characters
	for(row=0; row<MAX_ROWS; row++)
	{
		for(col=0; col<MAX_COLS; col++)
			print_char(' ', col, row, WHITE_ON_BLACK);
	}
	
	//Move the cursor back to the top left
	set_cursor(get_screen_offset(0, 0));
}
