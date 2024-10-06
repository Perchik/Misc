import argparse
import csv
import operator

# Define the standard operations, including concatenation if allowed


def get_operations(allow_concatenation):
    ops = {
        '+': (operator.add, '+'),
        '-': (operator.sub, '-'),
        '*': (operator.mul, '*'),
        # Handle division by zero
        '/': (lambda a, b: a / b if b != 0 else None, '/'),
        '^': (operator.pow, '^')
    }

    # Add concatenation if allowed
    if allow_concatenation:
        # No operator symbol for concatenation
        ops['concat'] = (lambda a, b: int(f"{a}{b}"), '')

    return ops

# Function to check if an equation is valid (LHS equals RHS)


def is_valid_equation(lhs_result, rhs_result):
    return lhs_result == rhs_result

# Function to generate valid clock times (4-digit) for either 12-hour or 24-hour format


def generate_valid_times(use_24hr=False):
    valid_times = []
    hour_range = range(0, 24) if use_24hr else range(
        1, 13)  # 00-23 for 24-hour, 01-12 for 12-hour
    for hour in hour_range:
        hour_str = f"{hour:02d}"  # Zero-padded hour
        for minute in range(60):  # Minutes from 00 to 59
            minute_str = f"{minute:02d}"  # Zero-padded minute
            # Concatenate to form a valid time (hhmm format)
            valid_times.append(hour_str + minute_str)
    return valid_times

# Precompute all pairs (result, equation) with the provided operations


def compute_pairs(digits, ops):
    pair_results = {}
    for i in range(len(digits)):
        for j in range(i + 1, len(digits)):
            d1, d2 = digits[i], digits[j]
            pair = (d1, d2)
            results = []
            for symbol, (op_func, op_symbol) in ops.items():
                try:
                    result = op_func(int(d1), int(d2))
                    if result is not None:
                        # Uniform logic for all operators, including concatenation
                        equation = f"{d1}{op_symbol}{d2}"
                        results.append((result, equation))

                    # Handle negatives after *, /, and ^
                    if op_symbol in ['*', '/', '^']:
                        result_with_negative = op_func(int(d1), -int(d2))
                        if result_with_negative is not None:
                            equation_with_negative = f"{d1} {op_symbol} -{d2}"
                            results.append(
                                (result_with_negative, equation_with_negative))
                except ZeroDivisionError:
                    continue

            pair_results[pair] = results
    return pair_results

# Compute all possible combinations for triples (digit, pair result) with the provided operations


def compute_triples(digits, pair_results, ops):
    triple_results = {}
    for i in range(len(digits)):
        for j in range(i + 1, len(digits)):
            for k in range(j + 1, len(digits)):
                d1 = digits[i]
                d2, d3 = digits[j], digits[k]
                pair = (d2, d3)

                if pair in pair_results:
                    for result, eq in pair_results[pair]:
                        results = []
                        for symbol, (op_func, op_symbol) in ops.items():
                            try:
                                # Normal case: combine digit with the pair's result
                                new_result = op_func(int(d1), result)
                                if new_result is not None:
                                    # Uniform logic for all operators, including concatenation
                                    new_equation = f"{d1}{op_symbol}({eq})"
                                    results.append((new_result, new_equation))

                                # Handle negatives for the pair result
                                if op_symbol in ['*', '/', '^']:
                                    new_result_with_negative = op_func(
                                        int(d1), -result)
                                    if new_result_with_negative is not None:
                                        new_equation_with_negative = f"{
                                            d1} {op_symbol} -({eq})"
                                        results.append(
                                            (new_result_with_negative, new_equation_with_negative))
                            except ZeroDivisionError:
                                continue

                        triple_results[(d1, d2, d3)] = results
    return triple_results

# Generate all valid equations for a specific time with optional debugging


def generate_equations_for_time(time_str, pair_results, triple_results, ops, debug=False):
    digits = list(time_str)

    if debug:
        print(f"\n--- Debugging Equation Generation for Time: {time_str} ---")

    # Case 1: D1 = Triple(D2, D3, D4)
    d1 = digits[0]
    remaining_digits = digits[1:]  # D2, D3, D4 are the remaining digits

    if tuple(remaining_digits) in triple_results:
        for triple_result, triple_eq in triple_results[tuple(remaining_digits)]:
            if debug:
                print(f"Considering: {d1} = {triple_eq}")
            if is_valid_equation(int(d1), triple_result):
                result = f"{d1} = {triple_eq}"
                if debug:
                    print(f"Valid equation found: {result}")
                return result
            elif debug:
                print(f"Invalid equation: {d1} != {triple_eq}")

    # Case 2: Pair(D1, D2) = Pair(D3, D4)
    left_pair = digits[:2]  # D1, D2
    right_pair = digits[2:]  # D3, D4

    if tuple(left_pair) in pair_results and tuple(right_pair) in pair_results:
        for lhs_result, lhs_eq in pair_results[tuple(left_pair)]:
            for rhs_result, rhs_eq in pair_results[tuple(right_pair)]:
                if debug:
                    print(f"Considering: {lhs_eq} = {rhs_eq}")
                if is_valid_equation(lhs_result, rhs_result):
                    result = f"{lhs_eq} = {rhs_eq}"
                    if debug:
                        print(f"Valid equation found: {result}")
                    return result
                elif debug:
                    print(f"Invalid equation: {lhs_eq} != {rhs_eq}")

    # Case 3: Triple(D1, D2, D3) = D4
    triple_digits = digits[:3]  # D1, D2, D3
    d4 = digits[3]  # D4

    if tuple(triple_digits) in triple_results:
        for triple_result, triple_eq in triple_results[tuple(triple_digits)]:
            if debug:
                print(f"Considering: {triple_eq} = {d4}")
            if is_valid_equation(triple_result, int(d4)):
                result = f"{triple_eq} = {d4}"
                if debug:
                    print(f"Valid equation found: {result}")
                return result
            elif debug:
                print(f"Invalid equation: {triple_eq} != {d4}")

    return None  # No valid equation found for this time

# Solve for all valid clock times, or for a specific time if provided


def solve_clock_equations(time_str=None, allow_concatenation=True, use_24hr=False, debug=False):
    ops = get_operations(allow_concatenation)
    valid_times = generate_valid_times(
        use_24hr=use_24hr) if time_str is None else [time_str]
    all_equations = {}
    valid_equation_count = 0  # To track how many times have valid equations

    for time in valid_times:
        digits = list(time)
        pair_results = compute_pairs(digits, ops)
        triple_results = compute_triples(digits, pair_results, ops)

        equation = generate_equations_for_time(
            time, pair_results, triple_results, ops, debug=debug)

        if equation:
            all_equations[time] = equation
            valid_equation_count += 1
            if debug:
                print(f"Time: {time}, Equation: {equation}")
        else:
            all_equations[time] = "NO_EQ"

    return all_equations, valid_equation_count

# Output the results to a CSV file


def output_to_csv(results, use_24hr, allow_concatenation, filename=None):
    # Dynamically generate the filename based on the flags
    time_mode = "24hr" if use_24hr else "12hr"
    concat_mode = "concat" if allow_concatenation else "noconcat"
    if not filename:
        filename = f"clock_eqs_{time_mode}_{concat_mode}.csv"

    with open(filename, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["Time", "Equation"])
        for time, equation in results.items():
            # Convert time from "hhmm" to "hh:mm"
            formatted_time = f"{time[:2]}:{time[2:]}"
            writer.writerow([formatted_time, equation])

    print(f"Results saved to {filename}")

# Main function to handle command-line arguments and run the program


def main():
    parser = argparse.ArgumentParser(
        description="Generate valid clock equations.")

    # Shortened flags for ease of use
    parser.add_argument('time', nargs='?', default=None,
                        help="Specific time in hhmm format (e.g., 1241). Leave empty to process all valid times.")
    parser.add_argument('--24', action='store_true',
                        help="Use 24-hour time format (default is 12-hour).")
    parser.add_argument('--concat', action='store_true',
                        help="Allow concatenation as a valid operation (default is False).")
    parser.add_argument('--debug', action='store_true',
                        help="Enable debug mode to see equation generation process.")
    parser.add_argument('--output', type=str, default=None,
                        help="Specify output CSV filename (optional).")

    args = parser.parse_args()

    # Solve for the specific time or all times based on the flags
    all_equations, valid_equation_count = solve_clock_equations(
        time_str=args.time,
        allow_concatenation=args.concat,
        use_24hr=args.__getattribute__('24'),
        debug=args.debug
    )

    # Output the results to a CSV file
    output_to_csv(all_equations, use_24hr=args.__getattribute__(
        '24'), allow_concatenation=args.concat, filename=args.output)

    # Print the summary of how many times had valid equations
    # 1440 possible times for 24hr, 720 for 12hr
    total_times = 1440 if args.__getattribute__('24') else 720
    print(f"\nValid equations found: {valid_equation_count} out of {
          total_times} possible times.")


# Entry point for the script
if __name__ == "__main__":
    main()
