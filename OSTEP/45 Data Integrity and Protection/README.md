## 45 Data Integrity and Protection

对输入的数据计算校验和，包括三种校验和函数
- 加法：二进制补码加法
- XOR：异或
- [Fletcher](https://en.wikipedia.org/wiki/Fletcher%27s_checksum)

```python
#  随机种子，默认为 0
parser.add_option('-s', '--seed', default='0', help='Random seed', action='store', type='int', dest='seed')
# 数据大小，默认为 4
parser.add_option('-d', '--data_size', default='4', help='Number of bytes in data word', action='store', type='int', dest='data_size')
# 指定数据
parser.add_option('-D', '--data', default='', help='Data in comma separated form', action='store', type='string', dest='data')
# 计算结果
parser.add_option('-c', '--compute', help='compute answers for me', action='store_true', default=False, dest='solve')
```

### 1

随机生成四个数字作为输入
- 加法：(216 + 194 + 107 + 66) % 256 = 71
- 异或：216 ⊕ 194 ⊕ 107 ⊕ 66 = 51
- Fletcher：73, 196
  - s1 = 0 + 216 % 255 = 216
  - s2 = 0 + 216 % 255 = 216
  - s1 = (216 + 194) % 255 = 155
  - s2 = (216 + 155) % 255 = 116
  - s1 = (155 + 107) % 255 = 7
  - s2 = (116 + 7) % 255 = 123
  - s1 = (7 + 66) % 255 = 73
  - s2 = (123 + 73) % 255 = 196

```bash
./checksum.py -c

# 输出
OPTIONS seed 0
OPTIONS data_size 4
OPTIONS data 

Decimal:          216        194        107         66 
Hex:             0xd8       0xc2       0x6b       0x42 
Bin:       0b11011000 0b11000010 0b01101011 0b01000010 

Add:             71       (0b01000111)
Xor:             51       (0b00110011)
Fletcher(a,b):   73,196   (0b01001001,0b11000100)
```

### 2

指定数据 `-D 1,2,3,4`
- 加法：(1 + 2 + 3 + 4) % 256 = 10
- 异或：1 ⊕ 2 ⊕ 3 ⊕ 4 = 4
- Fletcher：10， 20
  - s1 = (0 + 1) % 255 = 1
  - s2 = (0 + 1) % 255 = 1
  - s1 = (1 + 2) % 255 = 3
  - s2 = (1 + 3) % 255 = 4
  - s1 = (3 + 3) % 255 = 6
  - s2 = (4 + 6) % 255 = 10
  - s1 = (6 + 4) % 255 = 10
  - s2 = (10 +10) % 255 = 20

```bash
./checksum.py -D 1,2,3,4 -c

# 输出
OPTIONS seed 0
OPTIONS data_size 4
OPTIONS data 1,2,3,4

Decimal:            1          2          3          4 
Hex:             0x01       0x02       0x03       0x04 
Bin:       0b00000001 0b00000010 0b00000011 0b00000100 

Add:             10       (0b00001010)
Xor:              4       (0b00000100)
Fletcher(a,b):   10, 20   (0b00001010,0b00010100)
```