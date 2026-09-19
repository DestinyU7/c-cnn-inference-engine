.data
input:      .space 40000
weights:    .space 9
bias:       .space 1
output:     .space 40000

.text
.global _start
_start:
main:
// ---------- Main Procedure ----------
// x0 (n) will be set by armsim_convolution.py
LDUR X1, =input
LDUR X2, =weights
LDUR X3, =bias
LDUR X4, =output
BL convolution
exit:
// Exit sys call terminates program
MOV X8, #93
SVC 0

// ---------- Convolution Procedure ----------
// Parameters:
// x0 = n
// x1 = &input: pointer to N x N matrix of signed words
// x2 = &weights: pointer to 3 x 3 matrix of signed bytes
// x3 = &bias: pointer to a single signed byte
// x4 = &output: pointer to (N - 2) x (N - 2) matrix of signed words
// Register Mapping:
// x19 = j
// x20 = i
// x21 = y
// x22 = x
// x23 = sum
// x24 = n
// x25 = &input
// x26 = &weights
// x27 = &bias
// x28 = &output
convolution:
// Preserve LR and only necessary saved registers
SUB SP, SP, #48
STUR X19, [SP, #0]
STUR X20, [SP, #8]
STUR X21, [SP, #16]
STUR X22, [SP, #24]
STUR X23, [SP, #32]
STUR LR, [SP, #40]

// Preserve Parameters
// Move input size (n) to register X24
MOV X24, X0
// Move pointer to input matrix to register X25
MOV X25, X1
// Move pointer to weights to register X26
MOV X26, X2
// Move pointer to bias to register X27
MOV X27, X3
// Move pointer to output matrix to register X28
MOV X28, X4

// Preload bias into a register to avoid repeated memory access
LDURSB X8, [X27]

// Calculate n - 2 and store in X9, to be reused in loop conditions
SUB X9, X24, #2

// j = 0
MOV X19, XZR
convolution_loop_j:
// Compare j with (n - 2) to determine if the loop should continue
CMP X19, X9

// If j >= (n - 2), exit the loop
B.GE convolution_exit_loop_j

// i = 0
MOV X20, XZR
convolution_loop_i:
// exit if i >= n - 2
// Calculate n - 2 and store in X9
  
// Compare i with (n - 2) to determine if the loop should continue
CMP X20, X9
// If i >= (n - 2), exit the loop
B.GE convolution_exit_loop_i

// sum = bias (initialize sum with bias)
MOV X23, X8

// Unroll y loop manually (y = 0 to 2)
// y = 0
// Set x to 0 for unrolled x loop (y = 0)
MOV X22, XZR

// Calculate address for input[j + y][i + x]
// Stall: Depende on X19 (j) and X24 (n) for multiplication
MUL X10, X19, X24
// Stall: Depends on MUL result for address computation
ADD X10, X10, X20
// Stall: Depends on previous ADD result
LSL X10, X10, #2
// Stall: Address calculation needs on LSL result, wasteful
ADD X10, X10, X25
//  STALL Load input value from memory, X11 used immediately after load
LDURSW X11, [X10]
// Load weights[0][0]
LDURSB X12, [X26]
// Multiply input value by weight value, potential stall due to dependency on LDURSW
MUL X11, X11, X12
// Add result to sum, Stall: Dependent on MUL result
ADD X23, X23, X11
// INCREMENT X TO 1
ADD X10, X10, #4


// Load input value for x = 1
LDURSW X11, [X10]
// Load corresponding weight
LDURSB X12, [X26, #1]
// Multiply input value by weight value, Stall: DependS on LDURSW and LDURSB
MUL X11, X11, X12
// Add result to sum, Stall: Dpendent on MUL result
ADD X23, X23, X11


// x = 2
ADD X10, X10, #4
// Load-use hazard: X11 used immediately after load
LDURSW X11, [X10]
// Load weights[0][2]
LDURSB X12, [X26, #2]
// Stall: DependSS on LDURSW and LDURSB
MUL X11, X11, X12
 // Stall: Dependent on the MUL result
ADD X23, X23, X11


// y = 1
// Unroll x loop for y = 1
ADD X21, X19, #1
// Stall: Deendent on X21 (y) and X24 (n)
MUL X10, X21, X24
// sstall: Dependent on MUL result
ADD X10, X10, X20
// Stall: Depending on ADD result
LSL X10, X10, #2
ADD X10, X10, X25


// x = 0
// Load-use hazard: X11 used immediately after load
LDURSW X11, [X10]
LDURSB X12, [X26, #3]
// Stall: Depends on LDURSW and LDURSB
MUL X11, X11, X12
 // Stall: Dependent on MUL result
ADD X23, X23, X11


// x = 1
ADD X10, X10, #4
// Load-use hazard: X11 used immediately after load
LDURSW X11, [X10]
LDURSB X12, [X26, #4]
// Stall here: Dependent on LDURSW and LDURSB
MUL X11, X11, X12
// Stall: Dependent on MUL result
ADD X23, X23, X11


// x = 2
ADD X10, X10, #4
// Load-use hazard: X11 used immediately after load
LDURSW X11, [X10]
LDURSB X12, [X26, #5]
// Stall most likely: Dependent on LDURSW and LDURSB
MUL X11, X11, X12
// Stall happens here: Dependent on MUL result
ADD X23, X23, X11

// y = 2
// Unroll x loop for y = 2
ADD X21, X19, #2
 // Stalll: Dependiong on X21 (y) and X24 (n)
MUL X10, X21, X24
ADD X10, X10, X20
LSL X10, X10, #2
ADD X10, X10, X25


// x = 0
 // Load-use hazard: X11 used immediately after load
LDURSW X11, [X10] 
LDURSB X12, [X26, #6]
// Stall: Depending on LDURSW and LDURSB
MUL X11, X11, X12
// stall: Depends on MUL result
ADD X23, X23, X11


// x = 1
ADD X10, X10, #4
// Load-use hazard: X11 used immediately after load
LDURSW X11, [X10]
LDURSB X12, [X26, #7]
// Stall: Depending on LDURSWand LDURSB
MUL X11, X11, X12
ADD X23, X23, X11


// x = 2
ADD X10, X10, #4
// Load-use hazard: X11 used immediately after load
LDURSW X11, [X10]
LDURSB X12, [X26, #8]
// Stall: Depends on LDURSW and LDURSB
MUL X11, X11, X12
// stall: Dependent on MUL result
ADD X23, X23, X11

// Inline ReLU operation 
CMP X23, #0
B.GE relu_done
MOV X23, XZR
relu_done:

// Calculate address for output[j][i]
// x9 = &output + (j * (n - 2) + i) * 4

// Multiply (n - 2) by j and store in X9
// Potential stall: X9 used right after SUB X9, X24, #2 in the loops below, making it dependent
MUL X9, X9, X19

// Add i to compute offset for row/column
// Potential stall: This is dependent on the previous MUL, so there may be a delay waiting for the value of X9
ADD X9, X9, X20

// Multiply the result by 4 to calculate the word address
// This instruction may cause a stall as its dependent on the ADD result (dependent operations)
LSL X9, X9, #2

// Add the base address of the output matrix to compute the final address
ADD X9, X28, X9

// Store sum into output[j][i]
//  stall: This operation is dependent on the full address being calculated
STURW X23, [X9]


// Increment i and compare with (n - 2)
// Increment i (next element in the row)
ADD X20, X20, #1

// Calculate n - 2 and store in X9 again for comparison with i
// most likely stall: Dependency on X24 for calculation
SUB X9, X24, #2
  

// Compare i with (n - 2) to determine if loop should continue
CMP X20, X9

// If i < (n - 2), branch back to the start of the i-loop
B.LT convolution_loop_i

convolution_exit_loop_i:
// j++
// Increment j and compare with (n - 2)
// Increment j AGAIN (next row)
ADD X19, X19, #1


// Calculate n - 2 and store it in X9 again for comparison with j
//  stall: Dependent on X24 
  SUB X9, X24, #2

// Compare j with (n - 2) to determine if loop should continue
CMP X19, X9

// If j < (n - 2), branch back to the start of the j-loop
B.LT convolution_loop_j

convolution_exit_loop_j:
// Restore LR and only necessary saved registers
LDUR X19, [SP, #0]
LDUR X20, [SP, #8]
LDUR X21, [SP, #16]
LDUR X22, [SP, #24]
LDUR X23, [SP, #32]
LDUR LR, [SP, #40]
// Adjust stack pointer to restore stack
ADD SP, SP, #48
// Branch to LR to return from the procedure
BR LR
