# Plugs
# =====
#
# Plugs. They're sockets from the future.

zmq = require 'zmq'

# Binary is the default. Messages are passed to callbacks as Buffer objects
messageFormat = 'binary'
@messageFormat = (format) -> messageFormat = format

# Request/Reply Messaging

@reply = (urls...) ->
  zmqSocket = zmq.createSocket 'rep'
  for url in urls
    zmqSocket.bindSync url, (error) ->
      throw "can't bind to #{url}" if error?

  send = (msg) ->
    zmqSocket.send serialize msg

  createPlug zmqSocket, (callback) ->
    zmqSocket.on 'message', (buffer) ->
      callback parse(buffer), send

# alias
@rep = @reply

@request = (urls...) ->
  zmqSocket = zmq.createSocket 'req'
  for url in urls
    zmqSocket.connect url

  createPlug zmqSocket, (msg, callback) ->
    zmqSocket.on 'message', (buffer) ->
      callback parse(buffer)
    zmqSocket.send serialize msg

# alias
@req = @request


# Unidirectional (Pipeline) Messaging

@pull = (urls...) ->
  zmqSocket = zmq.createSocket 'pull'
  for url in urls
    zmqSocket.bindSync url, (error) ->
      throw "can't bind to #{url}" if error?

  createPlug zmqSocket, (callback) ->
    zmqSocket.on 'message', (buffer) ->
      callback parse(buffer)

@push = (urls...) ->
  zmqSocket = zmq.createSocket 'push'
  zmqSocket.connect url for url in urls

  createPlug zmqSocket, (msg) ->
    zmqSocket.send serialize msg


# Publish/Subscribe Messaging

@publish = (urls...) ->
  zmqSocket = zmq.createSocket 'pub'
  zmqSocket.bindSync url for url in urls

  createPlug zmqSocket, (msg) ->
    zmqSocket.send serialize msg

@pub = @publish

@subscribe = (urls...) ->
  zmqSocket = zmq.createSocket 'sub'
  zmqSocket.connect url for url in urls
  # subcribe to all messages (i.e. don't filter them based on a prefix)
  zmqSocket.subscribe ''

  createPlug zmqSocket, (callback) ->
    zmqSocket.on 'message', (buffer) ->
      callback parse(buffer)

@sub = @subscribe

# Implementation

# Annotates the plug function `f` with a reference to the zmq socket and adds
# a `close()` method
createPlug = (zmqSocket, f) ->
  f.socket = zmqSocket
  f.close = -> zmqSocket.close()
  f

parse = (buffer) ->
  switch messageFormat
    when 'utf8' then buffer.toString 'utf8'
    else buffer

serialize = (object) ->
  switch messageFormat
    when 'utf8' then new Buffer object
    else object
