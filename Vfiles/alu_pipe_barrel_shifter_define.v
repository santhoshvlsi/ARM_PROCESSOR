`define TAG_BITS_SIZE 4

`define REG_ADDR_SIZE 4

`define ALU_CONTROL_SIZE 4

`define FLAG_REGISTER_SIZE 4

`define REG_DATA_SIZE 32

`define REST_OF_CPSR_BITS_SIZE 28

/******ALU_PIPE_CONTROL_WORD******/
`define ALU_PIPE_CONTROL_WORD_SIZE 139

`define ALU_PIPE_CPSR_FLAG_START 138

`define ALU_PIPE_CARRY 136

`define ALU_PIPE_CPSR_FLAG_END 135

`define ALU_PIPE_REST_OF_CPSR_START 134

`define ALU_PIPE_CPSR_END 107

`define ALU_PIPE_OPERANDA_START 106

`define ALU_PIPE_OPERANDA_END 75

`define ALU_PIPE_OPERANDB_START 74

`define ALU_PIPE_OPERANDB_END 43

`define ALU_PIPE_IMM_FRM_INSTR_START 42

`define ALU_PIPE_IMM_FRM_INSTR_END 35

`define ALU_PIPE_REG_IMM_SEL 34

`define ALU_PIPE_RS_SHIFT_VALUE_START 33

`define ALU_PIPE_RS_SHIFT_VALUE_END 29

`define ALU_PIPE_SHIFT_VALUE_START 28

`define ALU_PIPE_SHIFT_VALUE_END 24

`define ALU_PIPE_SHIFT_OPCODE_START 23

`define ALU_PIPE_SHIFT_OPCODE_END 20

`define ALU_PIPE_RS_TO_SHIFT 19

`define ALU_PIPE_ALU_CONTROL_START 18

`define ALU_PIPE_ALU_CONTROL_END 15

`define ALU_PIPE_CTRL_CLZ 14

`define ALU_PIPE_COND_BITS_START 13

`define ALU_PIPE_COND_BITS_END 10

`define ALU_PIPE_CARRY_BARREL_SHIFTER_UPDATE 9

`define ALU_PIPE_INSTR_TAG_START 8

`define ALU_PIPE_INSTR_TAG_END 5

`define ALU_PIPE_RD_ADDR_START 4

`define ALU_PIPE_RD_ADDR_END 1

`define ALU_PIPE_START 0
/******ALU_PIPE_CONTROL_WORD******/

/******BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_CONTROL_WORD******/
`define BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_CONTROL_WORD_SIZE 55

`define BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_FLAG_START 54

`define BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_CARRY 52

`define BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_FLAG_END 51

`define BARREL_SHIFTER_STAGE_FOR_ALU_OPERAND_B_START 50

`define BARREL_SHIFTER_STAGE_FOR_ALU_OPERAND_B_END 19

`define BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_FROM_RS_START 18

`define BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_FROM_RS_END 14

`define BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_VALUE_START 13

`define BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_VALUE_END 9

`define BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_OPCODE_START 8

`define BARREL_SHIFTER_STAGE_FOR_ALU_SHIFT_OPCODE_END 5

`define BARREL_SHIFTER_STAGE_FOR_ALU_USE_RS_TO_SHIFT 4

`define BARREL_SHIFTER_STAGE_FOR_ALU_COND_BITS_START 3

`define BARREL_SHIFTER_STAGE_FOR_ALU_COND_BITS_END 0
/******BARREL_SHIFTER_STAGE_FOR_ALU_PIPE_CONTROL_WORD******/

/******ALU_STAGE_CONTROL_WORD******/
`define ALU_STAGE_CONTROL_WORD_SIZE 72

`define ALU_STAGE_CARRY 71

`define ALU_STAGE_OPERAND_A_START 70

`define ALU_STAGE_OPERAND_A_END 39

`define ALU_STAGE_OPERAND_B_START 38

`define ALU_STAGE_OPERAND_B_END 7

`define ALU_STAGE_CONTROL_START 6

`define ALU_STAGE_CONTROL_END 3

`define ALU_STAGE_CTRL_CLZ 2

`define ALU_STAGE_CARRY_BARREL_SHIFTER_UPDATE 1

`define ALU_CARRY_FRM_BARREL_SHIFTER 0
/******ALU_STAGE_CONTROL_WORD******/