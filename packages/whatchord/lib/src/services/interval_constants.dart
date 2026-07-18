/// Semitone interval offsets and mask bits used to build quality templates.
library;

const int chordRootInterval = 0;
const int minorSecondInterval = 1;
const int majorSecondInterval = 2;
const int minorThirdInterval = 3;
const int majorThirdInterval = 4;
const int perfectFourthInterval = 5;
const int tritoneInterval = 6;
const int diminishedFifthInterval = tritoneInterval;
const int sharpEleventhInterval = tritoneInterval;
const int perfectFifthInterval = 7;
const int minorSixthInterval = 8;
const int augmentedFifthInterval = minorSixthInterval;
const int majorSixthInterval = 9;
const int minorSeventhInterval = 10;
const int majorSeventhInterval = 11;

const int chordRootBit = 1 << chordRootInterval;
