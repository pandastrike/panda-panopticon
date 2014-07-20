// This JavaScript file contains the code neccessary to interact with Polymer's
// Shadow DOM and drive its functionality.

Polymer({

  PCW.AWSLogin = () ->
    # Estabilish authorized access to Amazon's servers.

    foo_1 = document.getElementById('login1').invalid
    foo_2 = window.document.getElementById('login2').invalid
    foo_3 = window.document.getElementById('login3').invalid

    alert foo_1 + foo_2 + foo_3

    # if foo_1 and foo_2 and foo_3
    #   # We may call Amzaon.  Prepare an AJAX call to our proxy server.
    #
    #   request = new XMLHttpRequest()
    #
    #   request.onreadystatechange =
    #     ->
    #         if request.readyState == 4 and request.status == 200
    #           # As soon as the list has been returned to the browser, we may continue.
    #           PCW.GeneratePlot request.responseText
    #
    #   request.open "POST", "http://localhost:3000/login", true
    #
    #
    #   # Prepare a comma delimited string that contains the credentials.
    #   message = ""
    #   message += document.getElementById('login1').inputValue + ","
    #   message += document.getElementById('login1').inputValue + ","
    #   message += document.getElementById('login1').inputValue
    #
    #   # Fire our AJAX call, including our message.
    #   request.send message
    #
    #
    # else
    #   # One of the fields is not filled out.
    #
    #   # Keep the dialog open.
    #   document.getElementBy('loginDialog').opened = true
    #
    #   # Show an error message.
    #   document.getElementById('toastLoginInvalid').show()



});
