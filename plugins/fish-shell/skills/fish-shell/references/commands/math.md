# Math Command Reference

Complete reference for `math` and `random` commands.

---

## math - Mathematical Calculations

```fish
math [OPTIONS] EXPRESSION ...
```

### Options

| Option | Description |
|--------|-------------|
| `-s N, --scale N` | Decimal places (0 for integer, "max" for maximum) |
| `-b BASE, --base BASE` | Output base: hex/16, octal/8 |
| `-m MODE, --scale-mode MODE` | truncate, round, floor, ceiling |

### Operators

| Operator | Description |
|----------|-------------|
| `+` | Addition |
| `-` | Subtraction |
| `*` or `x` | Multiplication (`*` needs quoting, `x` needs space after) |
| `/` | Division |
| `^` | Exponentiation |
| `%` | Modulo |
| `()` | Grouping (need quoting) |

### Constants

| Constant | Value |
|----------|-------|
| `e` | Euler's number (~2.718) |
| `pi` | Pi (~3.14159) |
| `tau` | 2*pi (~6.28318) |

### Functions

**Rounding:**
- `abs(x)` - Absolute value
- `ceil(x)` - Round up
- `floor(x)` - Round down
- `round(x)` - Round to nearest

**Trigonometry (radians):**
- `sin`, `cos`, `tan`
- `asin`, `acos`, `atan`, `atan2`
- `sinh`, `cosh`, `tanh`

**Logarithms:**
- `ln(x)` - Natural log
- `log(x)` or `log10(x)` - Base-10 log
- `log2(x)` - Base-2 log
- `exp(x)` - e^x

**Other:**
- `sqrt(x)` - Square root
- `pow(x,y)` - x to power y (same as x^y)
- `fac(x)` - Factorial
- `min(...)` - Minimum of values
- `max(...)` - Maximum of values
- `ncr(n,r)` - Combinations (n choose r)
- `npr(n,r)` - Permutations

**Bitwise:**
- `bitand(a,b)` - AND
- `bitor(a,b)` - OR
- `bitxor(a,b)` - XOR

### Examples

```fish
# Basic arithmetic
math 1 + 1        # 2
math 10 / 3       # 3.333333
math 2 ^ 10       # 1024

# Multiplication (escape or quote *)
math 5 \* 2       # 10
math "5 * 2"      # 10
math 5 x 2        # 10 (x with space)

# Integer output
math -s0 10 / 3   # 3

# More precision
math -s10 1 / 3   # 0.3333333333

# Using constants
math pi           # 3.141593
math "sin(pi)"    # 0
math "cos(pi)"    # -1

# Variables
set x 5
math $x + 3       # 8
math "$x * 2"     # 10

# Hexadecimal
math 0xFF         # 255
math --base=hex 192   # 0xc0

# Grouping (parentheses need quoting)
math "(5 + 3) * 2"    # 16

# Functions
math "sqrt(16)"       # 4
math "abs(-5)"        # 5
math "max(1,5,3)"     # 5
math "min(1,5,3)"     # 1
math "round(3.7)"     # 4
math "floor(3.7)"     # 3
math "ceil(3.2)"      # 4

# Factorial
math "fac(5)"         # 120

# Combinations
math "ncr(49,6)"      # 13983816

# Bitwise
math "bitand(0xFF, 0x0F)"   # 15
math "bitor(8, 4)"          # 12

# Complex expressions
math "sqrt(pow(3,2) + pow(4,2))"  # 5

# Underscores for readability
math 1_000_000 + 1    # 1000001
```

### Common Patterns

```fish
# Increment variable
set count (math $count + 1)

# Percentage
math "100 * $part / $total"

# Random in range (see random below)
math (random) % 100

# Check if divisible
if test (math $n % 2) -eq 0
    echo "even"
end
```

---

## random - Generate Random Numbers

```fish
random
random START END
random START STEP END
random choice ITEMS ...
```

### Usage

```fish
# Random 0-32767
random

# Random in range (inclusive)
random 1 100     # 1 to 100
random 0 10      # 0 to 10

# Random with step
random 0 2 10    # 0, 2, 4, 6, 8, or 10

# Random choice from list
random choice red green blue
random choice $mylist

# Simulate dice
random 1 6

# Coin flip
random choice heads tails

# Pick random file
set files *.txt
random choice $files
```

### Seeding (for reproducibility)

```fish
# Seed is set from system entropy by default
# Cannot be manually seeded in fish
```

---

## Common Mistakes (Bash Users)

| Bash | Fish |
|------|------|
| `$((1+1))` | `math 1+1` |
| `$((a++))` | `set a (math $a + 1)` |
| `$((a+=5))` | `set a (math $a + 5)` |
| `expr 1 + 1` | `math 1 + 1` |
| `bc <<< "1+1"` | `math 1 + 1` |
| `let a=1+1` | `set a (math 1+1)` |
| `$RANDOM` | `random` |
| `$((RANDOM % 100))` | `random 0 99` |

### Key Differences

1. **No in-place arithmetic** - Fish has no `((...))` syntax
2. **Floats by default** - `math 10/3` = 3.333, not 3
3. **Quote or escape `*` and `()`** - They're special in fish
4. **Use x for multiply** - `math 5 x 2` avoids glob issues

```fish
# Bash style (wrong)
# total=$((count + 1))

# Fish style (right)
set total (math $count + 1)
```
