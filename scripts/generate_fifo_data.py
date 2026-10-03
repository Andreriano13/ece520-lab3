# generate_fifo_data.py - ECE 520 Lab 3
# Makes sim/input_data.txt: the test words the testbench feeds into the FIFO.
# One 16-bit word per line, written as 4 hex digits (the testbench reads it with $readmemh).

WIDTH = 16          # data width in bits (matches the FIFO parameter)
DEPTH = 32          # FIFO depth (matches the FIFO parameter)

words = []                                   # the list of test words, in order

words += [0xFFFF] * DEPTH                    # test 1: all 1s, fill every slot
words += [0x0000] * DEPTH                    # test 2: all 0s        <-- YOUR TURN
words += [0xAAAA, 0x5555] * (DEPTH // 2)     # test 3: alternating   <-- YOUR TURN (AAAA's partner)
words += list(range(DEPTH))                   # test 4: 0,1,2,...,31 = every address once  <-- YOUR TURN

with open("../sim/input_data.txt", "w") as f:    # open the output file for writing
    for w in words:
        f.write(f"{w:04X}\n")                    # 4 uppercase hex digits, then a new line

print(f"wrote {len(words)} words to ../sim/input_data.txt")
