
#
# Practical Regular Expressions
#
# These are for practical _extraction_ (identifying potential examples), not
# validation (ensuring correctness). They may let nitpicks through that
# oughtn't: a time zone of `-0000` is illegal by the spec, but will pass the
# date regexp given below.


module Wu::Text::UsefulRegexps

  #  Double-quoted string: all backslash-escaped character, or non-quotes, up to first quote
  RE_QUOTED_STRING = %r{"((?:\\.|[^\"])*)"}
  # | Decimal number with sign: optional sign; digits-dot-digits
  RE_DECIMAL_NUMBER = %r{([\-\+\d]+\.\d+)}
  # Floating-point number. optional sign; digits-dot-digits; optional exponent
  RE_FLOAT_NUMBER = %r{([\+\-]?\d+\.\d+(?:[eE][\+\-]?\d+)?)}
  # ISO date. Capture groups are the year, month, day, hour, minute, second and time zone respectively.
  RE_ISO_DATE = %r{\b(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)([\+\-]\d\d:?\d\d|[\+\-]\d\d|Z)\b}

  #
  # Smiley face (emoticon) tokens
  #
  # http://mail.google.com/support/bin/answer.py?hl=en&answer=34056
  # http://en.wikipedia.org/wiki/Emoticons
  #
  # :-)  :)  =]  =)       Smiling, happy
  # :-(  =(  :[  :<       frowning, Sad
  # ;-)  ;)  ;]           Wink
  # :D   =D  XD  BD       Large grin or laugh
  # :P   =P  XP           Tongue out, or after a joke
  # <3   S2  :>           Love
  # :O   =O               Shocked or surprised
  # =I   :/  :-\          Bored, annoyed or awkward; concerned.
  # :S   =S  :?           Confused, embarrassed or uneasy
  #
  # Icon          Meaning                 Icon            Meaning                         Icon    Meaning
  # (^_^)         smile                   (^o^)           laughing out loud               d(^_^)b thumbs up (not ears)
  # (T_T)         sad (crying face)       (-.-)Zzz        sleeping                        (Z.Z)   sleepy person
  # \(^_^)/       cheers, "Hurrah!"       (*^^*)          shyness                         (-_-);  sweating (as in ashamed), or exasperated.
  # (*3*)         "Surprise !."           (?_?)           "Nonsense, I don't know."       (^_~)   wink
  # (o.O)         shocked/disturbed       (<.<)           shifty, suspicious              v(^_^)v peace
  #
  # [\\dv](^_^)[bv/]
  #
  #
  # Smileys !!! ^_^
  #
  RE_SMILEYS_EYES  = '\\:8;'
  RE_SMILEYS_NOSE  = '\\-=\\*o'
  RE_SMILEYS_MOUTH = 'DP@Oo\\(\\)\\[\\]\\|\\{\\}\\/\\\\'
  RE_KAWAII_EARS   = '\\*\\|!\\/=\\#o@v;\\:\\._'
  RE_EMOTICON = %r{
        (?:^|\W)                       # non-smilie character
        (
          (?: [\(\[#{RE_KAWAII_EARS}df\\]{0,3} \^[_\-]\^ [\]\)#{RE_KAWAII_EARS}Ab\/]{0,3} ) # super kawaaaaiiii!
         |(?:
            >?
            [#{RE_SMILEYS_EYES}]       # eyes
            [#{RE_SMILEYS_NOSE}]?      # nose, maybe
            [#{RE_SMILEYS_MOUTH}] )    # mouth
         |(?:
            [#{RE_SMILEYS_MOUTH}]      # mouth
            [#{RE_SMILEYS_NOSE}]?      # nose, maybe
            [#{RE_SMILEYS_EYES}]       # eyes
            <? )
         |(?: =[#{RE_SMILEYS_MOUTH}])  # =) =/
         |(?: [#{RE_SMILEYS_MOUTH}]=)  # /= (=
         |(?: \^[_\-]\^  )             # kawaaaaiiii!
         |(?: \((?:-_-|o\.O|T_T|\*\^\^\*|\^_~)\);? ) # more faces
         |(?: <3 )                     # heart
         |(?: \\m/ )                   # rawk
         |(?: x-\( )                   # dead
         |(?:XD|:>|:\?|:<|:\/)         # few more that don't fit the template
         |(?: :[,\']\( )               # snif  # make emacs non-unhappy: ']))
        )
        (?:\W|$)
       }xo

  RE_HASHTAGS = ORegexp.new( '(?:^|\W)\#([\w\-_\.+:=]+\w)(?:\W|$)', 'i', 'utf8' )

  # One or more $signs followed by letters or :^._
  # or string of $$$ signs on their own
  #
  # @example
  #    $AAPL
  #    $DJI^
  #    key$ha
  #    $$$$
  #    cash$
  #
  RE_STOCK_TOKEN  = %r{\$+[a-zA-Z\:\^\.\_]+|\$\$+}

  RE_DOMAIN_HEAD       = '(?:[a-zA-Z0-9\\-]+\\.)+'
  RE_DOMAIN_TLD        = '(?:[a-zA-Z][a-zA-Z]+)'
  # RE_URL_SCHEME      = '[a-zA-Z][a-zA-Z0-9\\-\\+\\.]+'
  RE_URL_SCHEME_STRICT = '[a-zA-Z]{3,6}'
  RE_URL_UNRESERVED    = 'a-zA-Z0-9'       + '\\-\\._~'
  RE_URL_OKCHARS       = RE_URL_UNRESERVED + '\'\\+\\,\\;=' + '/%:@'   # not !$&()* [] \|
  RE_URL_QUERYCHARS    = RE_URL_OKCHARS    + '&='
  RE_URL_HOSTPART      = "#{RE_URL_SCHEME_STRICT}://#{RE_DOMAIN_HEAD}#{RE_DOMAIN_TLD}"
  RE_URL               = %r{
        (       #{RE_URL_HOSTPART}                )    # Host
     (?:( \\/  [#{RE_URL_OKCHARS}]+?              )*?  # path:  / delimited path segments
        ( \\/  [#{RE_URL_OKCHARS}]*[\\w\\-\\+\\~] )    #        where the last one ends in a non-punctuation.
        |  )                                           #        ... or no path segment
        /?                                             #        with an optional trailing slash
        ( \\?  [#{RE_URL_QUERYCHARS}]+            )?   # query: introduced by a ?, with &foo= delimited segments
        ( \\\# [#{RE_URL_OKCHARS}]+               )?   # frag:  introduced by a #
      }ix

end

# if ($0 == __FILE__)
#   File.open('smiley_test.tsv').each do |line| ; line.chomp!
#     next if line.blank?
#     smiley_text, explanation = line.split("\t",2)
#     smiley_text.strip!
#     tweet = Tweet.from_hash('text' => line)
#     smiley = nil
#     tweet.smileys{ |a_smiley| smiley = a_smiley }
#     if ((! smiley) ||
#         (smiley.text != smiley_text.wukong_encode)
#         )
#       puts [line, smiley.to_flat].flatten.compact.join("\t")
#     end
#   end
# end
