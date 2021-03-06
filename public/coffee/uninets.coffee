
class Uninets
    settings:
        keep_alive: true
        keep_alive_token: 'test123'
        timeout: 300
        ws_url: 'ws://' + location.host + '/socket'
        ul_url: 'ws://' + location.host + '/userlist'

    flash: (message, cl) ->
        flash_msg = humane.create
        humane.log message, { timeout: 5000, clickToClose: true, addnCls: cl }

    getToken: () ->
        self = @
        $.get '/token', (msg) ->
            self.settings.keep_alive_token = msg.token

    getTimeout: () ->
        self = @
        $.get '/timeout', (msg) ->
            self.settings.timeout = msg.timeout

    chat: (keep_alive) ->
        self = @
        $('#msg').focus()

        $('#msg').keydown (e) ->
            if e.keyCode == 13
                chat_socket.send $('#msg').val()
                $('#msg').val('')

        log = (message) ->
            $('#log').val $('#log').val() + message + "\n"

        ul  = (list) ->
            $('#userlist').val ''
            $('#userlist').val $('#userlist').val() + user + "\n" for user in list

        chat_socket = new WebSocket self.settings.ws_url
        ul_socket   = new WebSocket self.settings.ul_url

        ul_socket.onopen = () ->
            ul ['fetching user list']

        ul_socket.onmessage = (msg) ->
            res = JSON.parse msg.data
            ul res.clients

        chat_socket.onopen = () ->
            log 'Connection opened'
            chat_socket.send 'connected'

        chat_socket.onmessage = (msg) ->
            res = JSON.parse msg.data
            log '[' + res.hms + '] ' + res.name + ': ' + res.text

        self.getToken()
        self.getTimeout()

        keep_alive_fun = () ->
            chat_socket.send self.settings.keep_alive_token
            ul_socket.send self.settings.keep_alive_token
            if keep_alive
                setTimeout keep_alive_fun, self.settings.timeout * 1000

        setTimeout keep_alive_fun, 1000

$(document).ready ->

    uninets = new Uninets

    $('html').removeClass 'no_js'
    $('.fancy-link').fancybox
        fitToView   : true
        autoSize    : true
        closeClick  : false
        openEffect  : 'none'
        closeEffect : 'none'

    $('.delete').click ->
        answer = confirm "Are you sure you want to delete the selected object?"

    if $('#chat_window').length > 0
        uninets.chat true

    if $('#flash-msg').length > 0
        text = $('#flash-msg').text()
        cls  = $('#flash-msg').attr 'class'
        $('#flash-msg').remove()
        uninets.flash text, cls

