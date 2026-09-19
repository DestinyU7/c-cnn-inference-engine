.data
// Global variables for print messages and 
// tracking correct and incorrect predictions
prediction_message: .asciz "0:0,0\n"
accuracy_message:   .asciz "000%\n"
correct_predictions: .byte 0
incorrect_predictions: .byte 0

.text

// Declare the functions as global, so that they can be found by the linker
.global linear
.global arg_max
.global report_prediction
.global report_accuracy

// ---------- Linear Procedure (Leaf) ----------
// Parameters:
//   X0: input
//   X1: weights
//   X2: biases
//   X3: output
linear:
// Initialize loop counter for output classes
    MOV X4, #0   
// Output class index (0 to 9)
OUTPUT_CLASS_LOOP:
    CMP X4, #10    
// Compare output class index with 10
    B.GE END_LINEAR           
// If index >= 10, exit the loop


    

// ---------- Argmax Procedure (Leaf) ----------
// Parameters:
//   X0: input
arg_max:
//Load first one into W1 that saves the max value then set initial index to 0
LDR  W1, [X0]
MOV X2,#0
//set initial index to 0

//setup the loop counter but start at 1
MOV X3,#1

ARGMAX_LOOP:
//now compare the array from 10
CMP X3,#10
//if X3 is greater than or equal to 10 then we move on
B.GE ARGMAX_RETURN
// Load the current element
ADD X4, X0, X3, LSL #2
// Calculate the address of [X3] logical shift left 2
LDR W5, [X4]         
// Load the current element into W5

//compare loaded w5 eleement with w1(our initial max value)
CMP W5,W1
B.LE ARG_NEXT        
// If W5 is less than or equal to W1, skip to the ARG_NEXT
// Update max value and max index
MOV W1, W5
// Update the max value to the new higher val        
MOV X2, X3
// Update the max index to the current index           

ARG_NEXT:
//go up the loop counter
ADD X3,X3,#1
//branch back to the original loop
B ARGMAX_LOOP

ARGMAX_RETURN:
// Return the index of the max value
MOV X0, X2  
// Set X0 to the index of the max value (this is our return value)
BR LR                
// Return from the function



// ---------- Report Prediction Procedure (Leaf) ----------
// Parameters:
// X0: image_index
// X1: expected_output
// X2: actual_output
report_prediction:
    // Reads the address of the global variables in X3 and X4
    LDR X3, =correct_predictions
    LDR X4, =incorrect_predictions

    // Load the values of the Global Variables
    MOV X5, XZR
    MOV X6, XZR
    LDRSB W5, [X3]
    LDRSB W6, [X4]

    // Compares the values of global variables
    SUBS XZR, X1, X2
    B.EQ ELSE
    // If not equal add 1 to incorrect_prediction
    ADD X6, X6, #1
    // Stores updates back into global variable
    STRB W6, [X4]
    B DONE

ELSE:
    // If equal add 1 to correct_prediction
    ADD X5, X5, #1
    // Stores updates back into global variable
    STRB W5, [X3]

DONE:
//make prediction message
    MOV W0, #58              
    // ASCII for ':'
    STRB W0, [X0]
    //store ascii for :
    MOV W0, #44              
    // ASCII for ','
    STRB W0, [X0,#1]
    //store ascii for ,
    MOV W0, #10              
    // ASCII for '\n'
    MOV W0, #0               
    // Null terminator NOT COMPLETE


    MOV X0, #1
    LDR X1, =prediction_message
    MOV X2, #7
    MOV X8, #64
    SVC 0

    MOV X8, #93
    SVC 0
    BR LR


// ---------- Report Accuracy (Leaf) ----------
// Parameters: None
report_accuracy:
    // Reads the address of the global variables in X3/X4
    LDR X3, =correct_predictions
    LDR X4, =incorrect_predictions

    // Load the values of the Global Variables
    MOV X5, XZR
    MOV X6, XZR
    LDRSB W5, [X3]
    LDRSB W6, [X4]

    // X9 stores total_predictions = correct_predictions + incorrect_predictions
    ADD X9, X5, X6

    // X10 stores accuracy = (correct_predictions * 100) // total_predictions
    MOV X11, #100
    MUL X10, X5, X11
    UDIV X10, X10, X9

    // Shift accuracy so that if under 3 digits there are 2 zeros in front
    CMP X10, #100
    B.LT LESS_HUNDRED
    B EXIT

LESS_HUNDRED:
    CMP X10, #10
    // Compare the accuracy value (X10) with 10
    B.LT LESS_TEN
    // If accuracy is less than 10, branch to LESS_TEN
    MOV X12, #10
    // Move the value 10 into register X12
    
    MUL X10, X10, X12
    // Multiply the accuracy value (X10) by 10 to shift it left by one decimal place
    LSR X10, X10, #1
    // Logical shift right by 1 to divide the result by 2 (effectively adjusting the value)

LESS_TEN:
    MUL X10, X10, X11
    // Multiply the adjusted accuracy value (X10) by 100 (stored in X11) to scale it up
    LSR X10, X10, #2
    // Logical shift right by 2 to divide the result by 4 (to adjust the scaling)

EXIT:
    MOV X0, #1
    //set x0 to 1
    LDR X1, =accuracy_message
    //load address of accuracy message
    MOV X2, #6
    //set x2 to 6
    MOV X8, #64
    //set x8 to 64
    SVC 0
    //call the system call
    MOV X8, #93
    SVC 0
    BR LR

