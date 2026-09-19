#ifndef SIMPLE_CNN_H

#define SIMPLE_CNN_H

#define INPUT_IMAGE_SIZE 28
#define TOTAL_OUTPUT_CLASSES 10
#define CONV_KERNEL_SIZE 5
#define TOTAL_KERNELS 6
#define CONV_OUTPUT_SIZE 24
#define MAX_POOL_WINDOW_SIZE 2
#define MAX_POOL_STRIDE 2
#define MAX_POOL_OUTPUT_SIZE 12
#define TOTAL_CONV_WEIGHTS (TOTAL_KERNELS * CONV_KERNEL_SIZE * CONV_KERNEL_SIZE)
#define TOTAL_LINEAR_WEIGHTS (TOTAL_OUTPUT_CLASSES * TOTAL_KERNELS * MAX_POOL_OUTPUT_SIZE * MAX_POOL_OUTPUT_SIZE)
#define DATASET_SIZE 20

typedef unsigned char IMAGE[INPUT_IMAGE_SIZE][INPUT_IMAGE_SIZE];
typedef signed char CONV_WEIGHT_MATRIX[TOTAL_KERNELS][CONV_KERNEL_SIZE][CONV_KERNEL_SIZE];
typedef signed char CONV_BIAS_MATRIX[TOTAL_KERNELS];
typedef signed int CONV_OUTPUT_MATRIX[CONV_OUTPUT_SIZE][CONV_OUTPUT_SIZE];
typedef signed int CONV_MAX_POOL_OUTPUT_MATRIX[TOTAL_KERNELS][MAX_POOL_OUTPUT_SIZE][MAX_POOL_OUTPUT_SIZE];
typedef signed char LINEAR_WEIGHT_MATRIX[TOTAL_OUTPUT_CLASSES][TOTAL_KERNELS][MAX_POOL_OUTPUT_SIZE][MAX_POOL_OUTPUT_SIZE];
typedef signed char LINEAR_BIAS_MATRIX[TOTAL_OUTPUT_CLASSES];
typedef signed int LINEAR_OUTPUT_MATRIX[TOTAL_OUTPUT_CLASSES];

extern signed int relu(signed int x);

extern void convolution_max_pool(IMAGE input, CONV_WEIGHT_MATRIX weights, CONV_BIAS_MATRIX biases, CONV_MAX_POOL_OUTPUT_MATRIX output);

extern void max_pool(signed int k, CONV_OUTPUT_MATRIX input, CONV_MAX_POOL_OUTPUT_MATRIX output);

extern void linear(CONV_MAX_POOL_OUTPUT_MATRIX input, LINEAR_WEIGHT_MATRIX weights, LINEAR_BIAS_MATRIX biases, LINEAR_OUTPUT_MATRIX output);

extern int arg_max(LINEAR_OUTPUT_MATRIX input);

extern void report_prediction(signed int image_index, signed int expected_output, signed int actual_output);

extern void report_accuracy();

#endif 