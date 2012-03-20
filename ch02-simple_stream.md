# Chapter 2: The Stream

In the system outlined in the previous chapter, a set of workers map each incoming letter to the order forms for each requested toy.

The letters come in from all over the world, though, and so we need a first step to translate them into the common tongue of the North Pole -- which as we all know is Pig Latin.

Let's write a program that can translate documents into Pig Latin by the billions.

## A Simple Streamer

The usual rules for changing standard English into Pig Latin are as follows:

* In words that begin with consonant sounds, the initial consonant or consonant cluster is moved to the end of the word, and "ay" is added, as in the following examples:
  - happy → appy-hay
  - question → estion-quay
  
* In words that begin with vowels, the syllable "way" is simply added to the end of the word.
  - another → another-way
  - about   → about-way

Write a program that converts english text to pig latin
    
    CONSONANTS = /bcdfghjklmnpqrstvwxz/
    UPPERCASE  = /[A-Z]/

    # Regular expression to identify the parts of a pig-latin-izable word
    PIG_LATIN_WORD_RE = %r{
      \b                  # word boundary
      ([#{CONSONANTS}]*)  # all initial consonants
      ([\w\']+)           # remaining word characters
      }xi                 # allow comments, case-insensitive

    mapper do |input|

      def latinize(line)
        latinized = line.gsub(PIG_LATIN_WORD_RE) do
          init, rest = [$1, $2]
          init = 'w'       if init.blank?
          rest.capitalize! if init =~ UPPERCASE
          "#{rest}-#{init.downcase}ay"
        end
        return latinized
      end

      input | map{|line| latinize(line) }
    end

Run it:

    wukong examples/text/pig_latin.rb data/magi.txt -

The last line should look like

    Everywhere-way ey-thay are-way isest-way. Ey-thay are-way e-thay agi-may.

**sidebar**: As a politeness to people coming here from other languages, code snippets in these early chapters are much wordier than what a ruby native would construct. We'll ease into a more vernacular style as the programs become more complex.


## About Streamers




## Exercises

### Exercise 1.1: Three Stupid but Useful Scripts

Write the following scripts:

* *null.rb*      -- emits nothing.
* *identity.rb*  -- emits every line exactly as it was read in.

These are kinda stupid, but useful for testing -- see exercise 1.2 for example.

### Exercise 1.2: Running time

It's important to build your intuition about what makes a program fast or slow. 

Let's run the *reverse.rb* and *piglatin.rb* scripts from this chapter, and the *null.rb* and *identity.rb* scripts from exercise 1.1, against the 30 Million Wikipedia Abstracts dataset.

First, though, write down an educated guess for how much longer each script will take than the `null.rb` script takes (use the table below). So, if you think the `reverse.rb` script will be 10% slower, write '10%'; if you think it will be 10% faster, write '- 10%'.

Next, run each script three times, mixing up the order. Write down 

* the total time of each run
* the average of those times
* the actual percentage difference in run time between each script and the null.rb script

        script     | est % incr | run 1 | run 2 | run 3 | avg run time | actual % incr |
        null:      |            |       |       |       |              |               |
        identity:  |            |       |       |       |              |               |
        reverse:   |            |       |       |       |              |               |
        pig_latin: |            |       |       |       |              |               |

Most people are surprised by the result.

### Exercise 1.3: Word count by Line

Create a script, `wc.rb`, that emit the length of each line, the count of bytes it occupies, and the number of words it contains. 

Notes:

* The `String` methods `chomp`, `length`, `bytesize`, `split` are useful here.
* Do not include the end-of-line characters (`\n` or `\r`) in your count.
* As a reminder -- for English text the byte count and length are typically similar, but the funny characters in a string like "Iñtërnâtiônàlizætiøn" require more than one byte each. The character count says how many distinct 'letters' the string contains, regardless of how it's stored in the computer. The byte count describes how much space a string occupies, and depends on arcane details of how strings are stored. 