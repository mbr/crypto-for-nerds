#!/usr/bin/python

from __future__ import print_function

import argparse
import daemon
import time


parser = argparse.ArgumentParser()
parser.add_argument('-f', '--foreground', action='store_true',
                    help='Do not daemonize.')
parser.add_argument('-i', '--input-rng', default='/dev/hwrng',
                    help='Input device to read from')
parser.add_argument('-o', '--output', default='/dev/random',
                    help='Output device to write to')
parser.add_argument('-b', '--bytes', default=512, type=int,
                    help='How many bytes to feed in at a time')
parser.add_argument('-t', '--interval', default=0.01, type=float,
                    help='Length of a timeslice during which bytes are fed '
                         'in')
parser.add_argument('-r', '--report-interval', default=1, type=float,
                    help='Reporting interval when running in foreground.')
args = parser.parse_args()


def main():
    count = 0
    now = time.time()
    last_report = now
    with open(args.input_rng, 'rb') as inp, open(args.output, 'wb') as out:
        while True:
            buf = inp.read(args.bytes)
            last_read = now

            while True:
                now = time.time()
                passed = now - last_read
                if passed < args.interval:
                    time.sleep(args.interval - passed)
                    continue
                break

            out.write(buf)
            count += len(buf)

            total = now - last_report
            if total >= args.report_interval:
                print('Fed {} bytes in {:.2f} seconds ({:.2f} bytes/sec)'
                      .format(count, total, count/total))

                count = 0
                last_report = now


if args.foreground:
    main()
else:
    with daemon.DaemonContext():
        main()
