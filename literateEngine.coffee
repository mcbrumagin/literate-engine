LiterateEngine = ->
  _ = @
  @context = {}

  @rules = []
  @extend = (rules...) -> _.rules.push rules...

  lookups = {}
  index = 0
  placeholder = (name) -> lookups[name] ?= "__#{index}__"

  replaceAll = (text) ->
    for phrase, key of lookups
      regex = new RegExp key, 'g'
      text = text.replace regex, phrase
    return text

  @eval = (script) ->
    paragraphs = script.split '\\n\\n'

    newParagraphs = []
    for paragraph in paragraphs
      stringRegex = new RegExp /".+?"/g

      newParagraphs.push paragraph.replace stringRegex, (match) ->
        placeholder match.slice 1, match.length - 1

    runRules = (sentence) ->
      console.log sentence
      # TODO: When to replace lookups?
      sentence = replaceAll sentence

      for property, value of _.context
        search = new RegExp property, 'g'
        while (match = search.exec sentence)?
          console.log 'Things!', match
          name = convertToCamel match[0]
          sentence = "#{
            sentence.slice 0, match.index
            }#{name}#{
              sentence.slice match.index + match[0].length
            }"
          console.log sentence:sentence
          # TODO need to keep camel-case and white-space delimited var in sync

      for rule in _.rules
        if rule.match
          #console.log rule.match
          regex = new RegExp rule.match
          while match = regex.exec sentence
            rule.fn.apply _.context, match
        if rule.replace
          #console.log rule.replace
          regex = new RegExp rule.replace
          sentence = sentence.replace regex,
            rule.val or rule.fn.call _.context
      console.log sentence

    script = newParagraphs.join '\\n\\n'
    sentences = script.split '.'
    runRules sentence for sentence in sentences

  return _

convertToCamel = (text) ->
  text.replace /(?:^\w|[A-Z]|\b\w|\s+)/g, (match, index) ->
    if +match is 0 then "" # or if (/\s+/.test(match)) for white spaces
    else if index is 0 then match.toLowerCase()
    else match.toUpperCase()

test = new LiterateEngine

test.extend
  replace: /plus/ig
  val: '+'
,
  replace: /minus/ig
  val: '-'
,
  replace: /times/ig
  val: '*'
,
  replace: /divided by/ig
  val: '/'
,
  match: /^\s?(?:let)\s(.+)\s(?:equal|=)\s(.+)$/ig
  fn: (match, name, expression) -> @[name] = eval expression
,
  match: /^\s?(?:print|log)\s(.+)$/ig
  fn: (match, name) -> console.log JSON.stringify "#{name}":@[name]


test.eval "Let my var equal (2 plus 2) times 4."
test.eval "Print my var."
test.eval "Let my var equal 2 plus 2 times 4."
test.eval "Print my var."
test.eval "
Let best variable equal 2 plus 2.
Let best variable equal best variable times 10.
Print best variable.
"
console.log context:test.context
