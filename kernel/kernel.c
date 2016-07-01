/*
	OS Kernel
	Jake Runge
	6/24/2016
*/

#include "../drivers/screen.h"

void main()
{
	//Create a pointer to a char; point it to the first text cell of video memory (top-left)
	print("32-bit Protected Mode successfully loaded.");
	print("\nNo more operations accessible at this time.\n\n");
	
	for(int i=0; i<210; i++) print(" Load! ");
}
