

    # # generate 100 files of 100,000 integers each; takes about 15 seconds to run
    # time ruby -e '10_000_000.times.map{|num| puts num }' | gsplit -l 100000 -a 2 --additional-suffix .tsv -d - numbers
    #
    # # in mapper, read N and generate `(0 .. 99).map{|offset| 100 * N + offset }`
