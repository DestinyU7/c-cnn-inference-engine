#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lodepng/lodepng.h"
#include "simple_cnn.h"

#pragma GCC diagnostic ignored "-Wincompatible-pointer-types"

void load_parameters(char* file_name, int size, signed char* output)
{
	FILE* file = fopen(file_name, "r");
	if (file == NULL) {
		printf("Error opening %s\n", file_name);
		exit(1);
	}

	signed char value;
	int read = 0;
	while (fscanf(file, "%hhd", &value) && read < size) {
		output[read++] = value;
	}

	if (read < size) {
		printf("Error: Too few parameters in %s, expected %d, found %d.\n", file_name, size, read);
		exit(1);
	}

    fclose(file);
}

void load_image(char* file_name, IMAGE output)
{
	unsigned char *image;
    unsigned int width, height;
    int error = lodepng_decode32_file(&image, &width, &height, file_name);
    if(error) {
        printf("Error %u: %s\n", error, lodepng_error_text(error));
        exit(1);
    }

    if (width != INPUT_IMAGE_SIZE || height != INPUT_IMAGE_SIZE) {
    	printf("Error: Image size (%d, %d) does not match expected size (%d, %d).\n", width, height, INPUT_IMAGE_SIZE, INPUT_IMAGE_SIZE);
    	exit(1);
    }
    
    for(unsigned int y=0; y<height; y++) {
        for(unsigned int x=0; x<width; x++) {
            int index = (y * width + x);
            output[y][x] = image[index * 4];
        }
    }

    free(image);
}

int main()
{
    CONV_WEIGHT_MATRIX conv_weights = {{{0}}};
	load_parameters("./parameters/conv_weights.txt", TOTAL_CONV_WEIGHTS, conv_weights);

    CONV_BIAS_MATRIX conv_biases = {0};
	load_parameters("./parameters/conv_biases.txt", TOTAL_KERNELS, conv_biases);

    LINEAR_WEIGHT_MATRIX linear_weights = {{{{0}}}};
	load_parameters("./parameters/linear_weights.txt", TOTAL_LINEAR_WEIGHTS, linear_weights);

    LINEAR_BIAS_MATRIX linear_biases = {0};
	load_parameters("./parameters/linear_biases.txt", TOTAL_OUTPUT_CLASSES, linear_biases);

    signed char dataset[DATASET_SIZE] = {0};
    load_parameters("./images/dataset.txt", DATASET_SIZE, dataset);
    for(int i=0; i<DATASET_SIZE; i+=2) {
        int image_index = dataset[i];
        int expected_output = dataset[i + 1];

        IMAGE image = {{0}};
        char file_name[] = "./images/0.png";
        file_name[9] = 48 + image_index;
        load_image(file_name, image);
        CONV_MAX_POOL_OUTPUT_MATRIX conv_pool_output = {{{0}}};
	    convolution_max_pool(image, conv_weights, conv_biases, conv_pool_output);
        LINEAR_OUTPUT_MATRIX linear_output = {0};
	    linear(conv_pool_output, linear_weights, linear_biases, linear_output);
        int actual_output = arg_max(linear_output);

        report_prediction(image_index, expected_output, actual_output);
    }

    report_accuracy();
	return 0;
}
