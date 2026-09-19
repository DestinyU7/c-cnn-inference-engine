from functools import reduce
from PIL import Image

INPUT_IMAGE_SIZE = 28
TOTAL_OUTPUT_CLASSES = 10
CONV_KERNEL_SIZE = 5
TOTAL_KERNELS = 6
CONV_OUTPUT_SIZE = 24
MAX_POOL_WINDOW_SIZE = 2
MAX_POOL_STRIDE = 2
MAX_POOL_OUTPUT_SIZE = 12
DATASET_SIZE = 20


def iterate_matrix(dimensions, current_index=None, depth=0):
    if current_index is None:
        current_index = [0] * len(dimensions)

    if depth == len(dimensions):
        yield tuple(current_index)
    else:
        for i in range(dimensions[depth]):
            current_index[depth] = i
            yield from iterate_matrix(dimensions, current_index, depth + 1)


def create_matrix(dimensions):
    return {index: 0 for index in iterate_matrix(dimensions)}


def set_matrix(matrix, dimensions, values):
    if len(matrix) != len(values):
        raise ValueError(f"Invalid number of values for given matrix: expected {len(matrix)} but got {len(values)}")

    for i, index in enumerate(iterate_matrix(dimensions)):
        matrix[index] = values[i]


def load_parameters(file_name, dimensions):
    with open(file_name, 'r') as f:
        try:
            parameters = [int(x) for x in f.read().split(' ')]
        except ValueError:
            raise ValueError(f"Parameters file contains unexpected characters")

    expected_size = reduce(lambda x, y: x * y, dimensions, 1)
    if len(parameters) != expected_size:
        raise ValueError("Wrong number of parameters found, "
                         + f"dimensions={dimensions}, expected_size={expected_size}, actual_size={len(parameters)}")

    matrix = create_matrix(dimensions)
    set_matrix(matrix, dimensions, parameters)
    return matrix


def load_image(file_name):
    image = Image.open(file_name)
    width, height = image.size
    if width != INPUT_IMAGE_SIZE or height != INPUT_IMAGE_SIZE:
        raise ValueError(f"Image size ({width}x{height}) does not match expected size ({INPUT_IMAGE_SIZE}x{INPUT_IMAGE_SIZE})")

    matrix = create_matrix((INPUT_IMAGE_SIZE, INPUT_IMAGE_SIZE))
    for y in range(height):
        for x in range(width):
            matrix[(y, x)] = int(image.getpixel((x, y)))
    return matrix


def relu(x):
    return max(0, x)


def convolution_max_pool(image, weights, biases, output):
    for k in range(TOTAL_KERNELS):
        convolution_output = create_matrix((CONV_OUTPUT_SIZE, CONV_OUTPUT_SIZE))
        for j in range(CONV_OUTPUT_SIZE):
            for i in range(CONV_OUTPUT_SIZE):
                _sum = 0
                for y in range(CONV_KERNEL_SIZE):
                    for x in range(CONV_KERNEL_SIZE):
                        _sum += image[(j + y, i + x)] * weights[(k, y, x)]
                convolution_output[(j, i)] = relu(_sum + biases[(k,)])

        max_pool(k, convolution_output, output)


def max_pool(k, _input, output):
    for j in range(MAX_POOL_OUTPUT_SIZE):
        for i in range(0, MAX_POOL_OUTPUT_SIZE):
            _max = 0
            for y in range(MAX_POOL_WINDOW_SIZE):
                for x in range(MAX_POOL_WINDOW_SIZE):
                    _max = max(_max, _input[(j * MAX_POOL_STRIDE + y, i * MAX_POOL_STRIDE + x)])
            output[(k, j, i)] = _max


def linear(_input, weights, biases, output):
    for n in range(TOTAL_OUTPUT_CLASSES):
        _sum = 0
        for k in range(TOTAL_KERNELS):
            for j in range(MAX_POOL_OUTPUT_SIZE):
                for i in range(MAX_POOL_OUTPUT_SIZE):
                    _sum += _input[(k, j, i)] * weights[(n, k, j, i)]

        output[(n,)] = (_sum + biases[(n,)])


def arg_max(_input):
    index = 0
    max_value = _input[(0,)]
    for i in range(1, TOTAL_OUTPUT_CLASSES):
        value = _input[(i,)]
        if value > max_value:
            max_value = value
            index = i
    return index


# Global variables for tracking the accuracy of the model.
# These values are mutated by the record_prediction function.

CORRECT_PREDICTIONS = 0
INCORRECT_PREDICTIONS = 0


def record_prediction(image_index, expected_output, actual_output):
    global CORRECT_PREDICTIONS
    global INCORRECT_PREDICTIONS

    if expected_output == actual_output:
        CORRECT_PREDICTIONS += 1
    else:
        INCORRECT_PREDICTIONS += 1

    print(f"{image_index}:{expected_output},{actual_output}")


def record_accuracy():
    global CORRECT_PREDICTIONS
    global INCORRECT_PREDICTIONS

    total_predictions = CORRECT_PREDICTIONS + INCORRECT_PREDICTIONS
    accuracy = (CORRECT_PREDICTIONS * 100) // total_predictions
    print(f"{accuracy:03}%")


def main():
    conv_weights = load_parameters('parameters/conv_weights.txt', (TOTAL_KERNELS, CONV_KERNEL_SIZE, CONV_KERNEL_SIZE))
    conv_biases = load_parameters('parameters/conv_biases.txt', (TOTAL_KERNELS,))
    linear_weights = load_parameters('parameters/linear_weights.txt',
                                     (TOTAL_OUTPUT_CLASSES, TOTAL_KERNELS, MAX_POOL_OUTPUT_SIZE, MAX_POOL_OUTPUT_SIZE))
    linear_biases = load_parameters('parameters/linear_biases.txt', (TOTAL_OUTPUT_CLASSES,))
    dataset = load_parameters('images/dataset.txt', (DATASET_SIZE,))

    for i in range(0, DATASET_SIZE, 2):
        image_index = dataset[(i,)]
        expected_output = dataset[(i + 1,)]

        image_filename = f"./images/{image_index}.png"
        image_matrix = load_image(image_filename)
        conv_max_pool_output = create_matrix((TOTAL_KERNELS, MAX_POOL_OUTPUT_SIZE, MAX_POOL_OUTPUT_SIZE))
        convolution_max_pool(image_matrix, conv_weights, conv_biases, conv_max_pool_output)
        linear_output = create_matrix((TOTAL_OUTPUT_CLASSES,))
        linear(conv_max_pool_output, linear_weights, linear_biases, linear_output)
        actual_output = arg_max(linear_output)

        record_prediction(image_index, expected_output, actual_output)

    record_accuracy()


if __name__ == '__main__':
    main()
