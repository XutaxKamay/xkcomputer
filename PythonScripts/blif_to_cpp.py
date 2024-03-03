import sys
import itertools

def calculate_output(input_values, partial_truth_table):
    for i in range(len(input_values)):
        if partial_truth_table[1][i] == '-':
            continue
        elif partial_truth_table[1][i] == '0' or partial_truth_table[1][i] == '1':
            if input_values[i] != int(partial_truth_table[1][i]):
                return 0
        else:
            assert("partial_truth_table[1][i] == " + partial_truth_table[1][i])
    return 1

def generate_truth_table(partial_truth_table):
    inputs = [''.join(map(str, x)) for x in itertools.product([0, 1], repeat=len(partial_truth_table[0]))]
    truth_table = {}

    for input_combination in inputs:
        input_values = [int(x) for x in input_combination]
        output = calculate_output(input_values, partial_truth_table)
        truth_table[input_combination] = output

    return truth_table

file_path = sys.argv[1]
file = open(file_path, "r")

lines = []
for line in file:
    lines.append(line)

model_name = ""
inputs = []
outputs = []
truth_tables = {}
constants = []
complete_truth_tables = {}

for line_index in range(len(lines)):
    line = lines[line_index]
    if ".model" in line:
        model_name = line.split()[1]
    elif ".inputs" in line:
        inputs = line.split()[1:] 
    elif ".outputs" in line:
        outputs = line.split()[1:]
    elif ".names" in line:
        names = line.split()[1:]

        if len(names) == 1:
            line_split = lines[line_index + 1].split()
            if ".names" in lines[line_index + 1]:
                constants.append([names[0], '0'])
            elif len(line_split) == 1:
                constants.append([names[0], '1'])
            else:
                assert("Shouldn't happen")
            continue

        output = names[-1]
        input_names = names[:-1]
        output_value = names[-1:]
        if output_value[0] != '1':
            assert("output_value is: " + output_value[0])

        line_split = lines[line_index + 1].split()
        input_values = line_split[:-1]
        truth_tables[output] = [input_names, input_values[0]]

print("Model name:", model_name)
print("Inputs:", inputs)
print("Outputs:", outputs)
print("Constants:", constants)
#print("Truth tables:", truth_tables)

for output in truth_tables:
    complete_truth_tables[output] = (truth_tables[output][0], generate_truth_table(truth_tables[output]))
    print(truth_tables[output][0], output)
    for inputs in complete_truth_tables[output][1]:
        print(inputs, complete_truth_tables[output][1][inputs])