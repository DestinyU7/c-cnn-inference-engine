# Compiler and Assembler
CC = gcc
AS = as

# Compiler flags
CFLAGS = -Wall -Wextra -g

# Include directories for lodepng
LODEPNG_INC = -Ilodepng

# Source files
SRC_C = main.c
SRC_ASM = simple_cnn_extended.s
LODEPNG_SRC = lodepng/lodepng.c

# Object files
OBJ_C = $(SRC_C:.c=.o)
OBJ_ASM = $(SRC_ASM:.s=.o)
LODEPNG_OBJ = $(LODEPNG_SRC:.c=.o)
OBJ = $(OBJ_C) $(OBJ_ASM)

# Output binary
TARGET = simple_cnn

# Default target
all: $(TARGET)

# Build the target
$(TARGET): $(OBJ) $(LODEPNG_OBJ)
	$(CC) $(CFLAGS) $(OBJ) $(LODEPNG_OBJ) simple_cnn.o -o $(TARGET)

# Compile C source files into object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Compile main.c with lodepng
main.o: main.c
	$(CC) $(CFLAGS) $(LODEPNG_INC) -c $< -o $@

# Compile lodepng into an object file
$(LODEPNG_OBJ): $(LODEPNG_SRC)
	$(CC) $(CFLAGS) $(LODEPNG_INC) -c $< -o $@

# Assemble assembly files into object files
%.o: %.s
	$(AS) $< -o $@

# Clean up
clean:
	rm -f $(OBJ) $(LODEPNG_OBJ) $(TARGET)

# Phony targets
.PHONY: all clean
