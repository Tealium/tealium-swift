import sys
import re
filename = str(sys.argv[1])
from decimal import Decimal
with open(filename) as f:
	lines = f.readlines()
	line = lines[2]
	print(line)
	coverage = re.findall('\d*\.?\d+',line)[2]
	print(coverage)
	if Decimal(coverage) > 65.0:
		sys.exit(0)
	else:
		sys.exit(1)