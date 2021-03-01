import sys
import urllib.request
import json
from decimal import Decimal

url = str(sys.argv[1])
req = urllib.request.Request(url)
res = urllib.request.urlopen(req).read()
content = json.loads(res.decode('utf-8'))

if len(content):
	latest = content['commits'][0]
	if 'totals' in latest:
		totals = latest['totals']
		if 'c' in totals:
			coverage = totals['c']
			print("Coverage: ", coverage)
			if Decimal(coverage) > 65.0:
				sys.exit(0)
			else:
				sys.exit(1)
