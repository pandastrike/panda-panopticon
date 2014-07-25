#===============================================================================
# PandaPandaCloudWatch is a data visiualization tool for Amazon Web Services.
# The idea is to keep things simple and Web-native.   We make use of Dygraph
# a data visualization library written in JavaScript that acts of HTML div elements.
# Data is accessed from AWS via Amazon's javascript API.
#
# This tool is written in CoffeeScript.
#
#===============================================================================

window.PCW = {}
window.Dashboard = {}

PCW.instance_list = []
PCW.tag_list = []
PCW.match_list = []

Dashboard.InitializeEvents = () ->
  # Event Listeners for things not as simple as push-buttons.

  # In the Options dialog, this adjusts the view based on which tab is open.
  option_tabs = document.getElementById("optionTabs")
  option_tabs.addEventListener "core-select",
  ->
    # Hide the current view.
    document.getElementById('option_0').style.display = "none"
    document.getElementById('option_1').style.display = "none"
    document.getElementById('option_2').style.display = "none"

    # Show the selected view.
    name = "option_" + option_tabs.selected
    document.getElementById(name).style.display = "block"


  filter_type_radio = document.getElementById "filter_type"
  filter_type_radio.addEventListener "core-select",
  ->
    # This radio group controls what is shown in selector.  It can either be a list
    # of instance IDs or tag names.  The code to handle these actions are bundled in
    # helper functions.

    if filter_type_radio.selected == "filter_instance"
      Dashboard.PopulateInstanceSelector()

    else
      Dashboard.PopulateTagSelector()


Dashboard.ToggleDialog = (name) ->

  document.getElementById(name).toggle()


Dashboard.DeleteDuplicateTags = () ->
  # This function eliminates duplicate tag names from PCW.tag_list.  This ensures
  # only unique tag names are presented to the User.

  if PCW.tag_list.length > 1
    temp_list = []
    hold = PCW.tag_list[0]

    # The list is sorted, so we need only compare an item to those that follow it before moving on.
    for i in [1..PCW.tag_list.length - 1]
      if PCW.tag_list[i] == hold
        # This is a duplicate.  Keep going.
      else
        # We have found a unique tag.
        temp_list.push hold
        hold = PCW.tag_list[i]

      if i == PCW.tag_list.length - 1 and hold != temp_list[temp_list.length - 1]
        temp_list.push hold

    # Now replace the offical list with the one we just created.
    PCW.tag_list = temp_list



Dashboard.PopulateInstanceSelector = () ->
  # This function populates the "filter by" selector in the UI.  In this case, with Instance IDs.
  selector = document.getElementById "filterSelector"

  # Clear the selector of any children.
  selector.innerHTML = ''

  # Append children, one for every instance selection item.
  for i in [0..PCW.instance_list.length - 1]
    name = document.createElement "div"
    name.innerHTML = PCW.instance_list[i]
    name.id = PCW.instance_list[i]
    name.className = "filter"
    selector.appendChild name


  # The default behavior is to have all the elements selected.
  Dashboard.SelectAll("filterSelector")


Dashboard.PopulateTagSelector = () ->
  # This function populates the "filter by" selector in the UI.  In this case, with Tag Names.
  selector = document.getElementById "filterSelector"

  # Clear the selector of any children.
  selector.innerHTML = ''

  # Append children, one for every tag selection item.
  for i in [0..PCW.tag_list.length - 1]
    name = document.createElement "div"
    name.innerHTML = PCW.tag_list[i]
    name.className = "filter"
    selector.appendChild name


  # The default behavior is to have all the elements selected.
  Dashboard.SelectAll("filterSelector")


Dashboard.SelectAll = (name) ->
  # This dialog takes the source target selector element from the UI and activates all selections.
  selector = document.getElementById name

  # All we need to do is call the attribute "selected" and feed it an array of indeces.
  # Polymer takes care of the rest.
  select_array = []
  for i in [0..selector.childNodes.length - 1]
    select_array.push i

  selector.selected = select_array


Dashboard.SelectNone = (name) ->
  # This dialog takes the source target selector element from the UI and de-activates every selection.
  selector = document.getElementById name

  # All we need to do is call the attribute "selected" and feed it null.
  # Polymer takes care of the rest.
  selector.selected = null








PCW.AWSLogin = () ->
  # Estabilish authorized access to Amazon's servers.


  foo_1 = document.getElementById('login1').invalid
  foo_2 = window.document.getElementById('login2').invalid
  foo_3 = window.document.getElementById('login3').invalid

  if foo_1 == false and foo_2 == false and foo_3 == false
    # We may call Amzaon.  Prepare an AJAX call to our proxy server.

    request = new XMLHttpRequest()
    request.open "POST", "/login", true

    # Prepare a comma delimited string that contains the credentials.
    message = ""
    message += document.getElementById('login1').inputValue + ","
    message += document.getElementById('login2').inputValue + ","
    message += document.getElementById('login3').inputValue

    request.onreadystatechange =
      ->
          if request.readyState == 4
            # As soon as the list has been returned to the browser, we may continue.
            if request.status != 200
              # Login failed, but everything worked on our end.

              # Keep the dialog open.
              document.getElementById('loginDialog').toggle()

              # Prepare the error message.
              document.getElementById('toastMessage').text =
              "Apologies. Amazon has declined this login.   Reason: " + request.responseText

              document.getElementById('toastMessage').show()

            else
              # Success.

              # Parse the proxy server's response, "responseText".
              temp = request.responseText.split ";"

              PCW.user_token = temp[0]
              PCW.instance_list = temp[1].split ","
              PCW.tag_list = temp[2].split ","

              for i in [3..temp.length - 1]
                PCW.match_list.push PCW.instance_list[i] + "," + temp[i]


              PCW.instance_list.sort()
              PCW.tag_list.sort()

              # We need to eliminate duplicates from "tag_list", so we only present unique tags.
              Dashboard.DeleteDuplicateTags()

              # With the duplicates gone, we need to be able to associate a given
              # tag with instance(s) it represents.
              PCW.LinkTagsToInstances()

              # Populate filter selector.  The default behavior is to display selected instance IDs.
              Dashboard.PopulateInstanceSelector()

              # Do the same for the metrics selector.
              Dashboard.SelectAll("metricSelector")

              # Scrub the credentials from memory and the HTML fields.
              message = ""
              document.getElementById('login1').value = ""
              document.getElementById('login2').value = ""
              document.getElementById('login3').value = ""

              # Tell the User we're good to go.
              document.getElementById('toastMessage').text = "Success!  Connection established."
              document.getElementById('toastMessage').show()

              # Change the control bar's button's to reflect this new access.
              document.getElementById('loginButton').style.display = "none"
              document.getElementById('optionButton').style.display = "block"
              document.getElementById('plotButton').style.display = "block"


    # Fire our AJAX call, including our message.
    request.send message


  else
    # One of the fields is not filled out.

    # Keep the dialog open.
    document.getElementById('loginDialog').toggle()

    # Show an error message.
    document.getElementById('toastMessage').text = "Apologies. AWS Login cannot occur without full credentials."
    document.getElementById('toastMessage').show()



PCW.LinkTagsToInstances = () ->
  # This function will create two arrays of objects.  We will be able to use these to:
  # 1) Associate an instance with a list of tags, for labeling on plots and
  # 2) Associate a tag with a list of instances, to allow the User a way to meaningful way to call instances.

  PCW.instance_with_tags = []
  PCW.tag_with_instances = []

  # One instance to many tags.
  for x in PCW.match_list
    foo = x.split ","
    instance_id = foo[0]
    foo.splice 0, 1

    bar = {
      instance: instance_id,
      tags: foo
    }

    PCW.instance_with_tags.push bar


  # One tag to many instances.
  for foo in PCW.tag_list
    temp = []

    for bar in PCW.instance_with_tags
      if foo in bar.tags
        temp.push bar.instance

    obj = {
      tag: foo,
      instances: temp
    }

    PCW.tag_with_instances.push obj







PCW.PullMetrics = () ->
  # This makes an AJAX call to our proxy server.  We send it User specified parameters and
  # repeat for each instance and metric we're interested in.  Once we have "responseText",
  # we pass that to the next functions that do the additional work to parse and plot the data.

  # Prepare a comma delimited string containing the options specified by the user. Since
  # this is going to get messy, a helper function has been built elsewhere.
  message = PCW.PrepOptionString()


  # Just check for any error messages from the helper.
  if message == "Total Filter Deselection"
    # The User has deselected all instances.  We cannot continue.
    document.getElementById('toastMessage').text = "Apologies. You must select at least
    one instance or tag to pull metrics."

    document.getElementById('toastMessage').show()
    return

  else if message == "Total Metric Deselection"
    # The User has deselected all metrics.  We cannot continue.
    document.getElementById('toastMessage').text = "Apologies. You must select at least
    one metric to display data."

    document.getElementById('toastMessage').show()
    return


  # Since we made it through, this request is going to happen. Let's get some stuff setup on the UI.

  # Clear the plot area.
  document.getElementById('plot_area').innerHTML = ''

  # Create enough plots to handle the number of metrics requested.
  for i in [0..PCW.metric_pull_list.length - 1]
    temp = document.createElement "div"
    temp.id = "plot_" + i
    temp.className = "plot"
    document.getElementById('plot_area').appendChild temp

  # This recursive AJAX call is going to take some time to complete. We need to lampshade
  # that fact by providing a progress bar on the page to let the User know that the page working.
  for i in [0..PCW.metric_pull_list.length - 1]
    bar = document.createElement('paper-progress')
    bar.id = "download_bar_" + i
    bar.min = 0
    bar.max = PCW.target_pull_list.length - 1
    bar.value = 0
    target = document.getElementById('plot_' + i)
    target.appendChild bar




  PCW.final_series = []

  request = new XMLHttpRequest()
  request.open "POST", "/pull_metrics", true

  # Create the first message to send to the proxy server.
  message = PCW.user_token + ";" + PCW.time_parameters + ";" + PCW.target_pull_list[0] + ";" + PCW.metric_pull_list[0]
  PCW.target_index = 0
  PCW.metric_index = 0

  # Start the process of recursively calling Amazon.
  PCW.CallAmazon request, message

PCW.CallAmazon = (request, message)->

  # Because AJAX is asynchronous, we cannot use a for-loop.  We instead setup chaining calls
  # within this response function.
  request.onreadystatechange =
    ->
		    if request.readyState == 4
          if request.status != 200
            # Something bad happened.

            # Prepare the error message.
            document.getElementById('toastMessage').text =
            "Apologies. Something went wrong...   Reason: " + request.responseText

            document.getElementById('toastMessage').show()


          else
            # We have the response.  Continue.

            # First, parse what we got back from the proxy server.
            PCW.ParseResponse request.responseText

            # Update the progress bar.
            bar_id = 'download_bar_' + PCW.metric_index
            document.getElementById(bar_id).value = String(PCW.target_index)


            # Next, move on to the other requests.  The following control structure
            # keeps track of where we are and what to call next.

            if PCW.target_index < PCW.target_pull_list.length - 1
              # We have not exhausted the target list.  Go to the next target within this metric.
              PCW.target_index++

              # Prepare
              request = new XMLHttpRequest()
              request.open "POST", "/pull_metrics", true
              message = PCW.user_token + ";" + PCW.time_parameters + ";" + PCW.target_pull_list[PCW.target_index] +
              ";" + PCW.metric_pull_list[PCW.metric_index]

              # Fire
              PCW.CallAmazon request, message

            else
              # We have exhausted the target list for this metric.  We are ready to plot this data.
              PCW.DrawPlot()
              PCW.final_series = []

              # Now we reset the target index, move to the next metric, and repeat.

              if PCW.metric_index < PCW.metric_pull_list.length - 1
                # We have not exhausted the list of metrics.  Keep going.
                PCW.target_index = 0
                PCW.metric_index++

                # Prepare
                request = new XMLHttpRequest()
                request.open "POST", "/pull_metrics", true
                message = PCW.user_token + ";" + PCW.time_parameters + ";" + PCW.target_pull_list[PCW.target_index] +
                ";" + PCW.metric_pull_list[PCW.metric_index]

                # Fire
                PCW.CallAmazon request, message


              # If we made it past the if statement, we have exhausted the list of metrics.
              # We are finally done.




  # Fire the first AJAX call, including the message string.   Cross your fingers.
  request.send message



PCW.PrepOptionString = () ->
  # This function contains all the code we need to turn the plot options the User has
  # specified into a single string, "message", for the proxy server to parse.

  message = ""

  # Let's start with Timeframe options.

  # 1) Timespan

  # We take the input number and multiply a conversion based on the units the User requested.
  # We need to get from the User's units to miliseconds.
  if document.getElementById("timespan_radio").selected == "timespan_minutes"
    temp = document.getElementById("timespan").inputValue * 60 * 1000

  else if document.getElementById("timespan_radio").selected == "timespan_hours"
    temp = document.getElementById("timespan").inputValue * 60 * 60 * 1000

  else
    temp = document.getElementById("timespan").inputValue * 24 * 60 * 60 * 1000

  # Apply some constraints.
  # Keep the timespan >= 5 minutes.
  if temp < 300000
    temp = 300000

  # Keep the timespan <= 2 weeks.
  if temp > 1209600000
    temp = 1209600000

  # Amazon only accepts time in ISO 8601 format to avoid amiguity.
  d = new Date()
  start = new Date(d.getTime() - temp).toISOString()
  end = new Date(d.getTime()).toISOString()

  message += start + "," + end + ","



  # 2) Sampling Resolution

  # We take the input number and multiply a conversion based on the units the User requested.
  # We need to get from the User's units to seconds.
  if document.getElementById("resolution_radio").selected == "resolution_minutes"
    temp = document.getElementById("resolution").inputValue * 60

  else if document.getElementById("resolution_radio").selected == "resolution_hours"
    temp = document.getElementById("resolution").inputValue * 60 * 60

  else
    temp = document.getElementById("resolution").inputValue * 24 * 60 * 60

  # Apply some constraints.
  # Keep the resolution >= 1 minute.
  if temp < 60
    temp = 60

  # Keep the resolution <= than 1 week.
  if temp > 604800
    temp = 604800

  message += temp

  PCW.time_parameters = message
  message = ""



  # Next, we move on to Filter Options.  These are not placed directly into the message.
  # We instead place them into a global variable to be handled iteratively in the AJAX request.

  # Figure out if we're filtering by Instance IDs or Tag Names.
  selector = document.getElementById 'filterSelector'
  PCW.target_pull_list = []

  if document.getElementById('filter_type').selected == "filter_instance"
    # We're filtering by Instance ID.
    temp = selector.selectedItem
    for i in temp
      PCW.target_pull_list.push i.innerHTML

    if PCW.target_pull_list == null
      # The User has deselected all instances.  We cannot continue.
      return "Total Filter Deselection"

  else
    # We're filtering by Tag Name.
    temp = selector.selectedItem

    if temp == null
      # The User has deselected all tags.  We cannot continue.
      return "Total Filter Deselection"

    # Since the User is filtering by Tags, we'll have to translate those into instance ID or IDs.
    for item in temp
      for tag in PCW.tag_with_instances
        if item.innerHTML == tag.tag
          for instance in tag.instances
            if instance not in PCW.target_pull_list
              PCW.target_pull_list.push instance




  # Next, we move on to Metric Options.  These are not placed directly into the message.
  # We instead place them into a global variable to be handled iteratively in the AJAX request.
  selector = document.getElementById 'metricSelector'
  PCW.metric_pull_list = []

  temp = selector.selectedItem
  for i in temp
    PCW.metric_pull_list.push i.id

  if PCW.metric_pull_list == null
    # The User has deselected all metrics.  We cannot continue.
    return "Total Metric Deselection"


  # If we made it to the end, we're good to go.
  return message



PCW.ParseResponse = (response_string) ->
  # This function parses the response from our proxy server.  The response is a string
  # containing serialized (though unsorted), time-sequence data.  We are preparing this
  # for plotting using the HighCharts library.  For a given plot, it accepts data in the following format.

  # series:[{
  #   name: String -> label as apears on plot for a single data set,
  #   data: [[x1, y1], [x2, y2], ...] -> x and y-axis values of time-ordered data.
  # }]

  # Each data set gets its own object inside the "series" array.

  # While dividing the string is easy, the data is unfortunately out of time-squence order.
  # First, parse the string.  We aim to create an array of objects for us to sort.
  series = response_string.split ";"
  data = []



  if series.length != 1
    for i in [0..series.length - 1]
      datum = series[i].split ","

      temp = {
        Timestamp: datum[0],
        Value: datum[1]
      }

      data.push temp


    # Now we may begin sorting.  To make things easier, we convert the timestamps to Unix Epoch
    # time.  Comparing timestamps becomes simple numerical comparison.
    for i in [0..data.length - 1]
      d = new Date(data[i].Timestamp)
      data[i].Timestamp = d.getTime()

    # Now, sort the objects.
    data.sort( (a, b)->

      if a.Timestamp > b.Timestamp
        return 1

      else if a.Timestamp < b.Timestamp
        return -1

      else
        return 0
    )

    # Sorting complete.
    # Next, we need to adjust these times from UTC time to the local timezone.
    # Get the offset and convert to milliseconds.
    d = new Date()
    offset = d.getTimezoneOffset() * 60000

    for i in [0..data.length - 1]
      data[i].Timestamp -= offset

    # Now, we can finally package the data for plotting.  Our goal is to add to a global array.  This
    # array contains objects that hold plotting data...  data that is formatted
    # according to the specifications in the comments at the start of this function.

    # Data
    temp = []
    for i in [0..data.length - 1]

      foo = []
      foo.push Number(data[i].Timestamp)
      foo.push Number(data[i].Value)

      temp.push foo

    # Data Label
    label = '<b>Instance ID: </b>' + PCW.target_pull_list[PCW.target_index] + '<br>' +
    '<b>Tags: </b> '
    for instance in PCW.instance_with_tags
      if instance.instance == PCW.target_pull_list[PCW.target_index]
        for tag in instance.tags
          label += tag + '<br>'

    bar = {
      name: String label
      data: temp
    }

    # Add this object to the global array.
    PCW.final_series.push bar


PCW.DrawPlot = () ->

  # Plotting is accomplished with the HighCharts graphing library, which uses just
  # a touch of jQuery to function properly.

  # We need to feed this plotting function an object that specifies plotting options.

  # Get the start time from ISO 8601 to Unix Epoch time and feed it into the params object.
  temp = PCW.time_parameters.split ","
  time_range = temp[0]
  d = new Date time_range
  e = new Date()
  time_range = e.getTime() - d.getTime()

  # Label the y-axis appropriately.
  if PCW.metric_pull_list[PCW.metric_index] == "CPUUtilization"
    ylabel = "Percentage"

  else if PCW.metric_pull_list[PCW.metric_index] == "DiskReadOps" or
        PCW.metric_pull_list[PCW.metric_index] == "DiskWriteOps"
    ylabel = "Count"

  else
    ylabel = "Bytes"

  params = {
        title: {
            text: String(PCW.metric_pull_list[PCW.metric_index]),
            x: -20 #center
        },
        tooltip: {
          headerFormat: '<span style="font-size: 12px"><b>Value: </b> {point.y} <br>
           <b>Time: </b> {point.key}</span><br>',
          pointFormat: '{series.name}'
        },
        xAxis: {
            type: 'datetime',
            minRange: time_range
        },
        yAxis: {
            title: {
                text: ylabel
            },
            plotLines: [{
                value: 0,
                width: 1,
                color: '#808080'
            }],
            floor: 0
        },
        legend: {
          enabled: false
        }
        series: PCW.final_series
    }


  # Everything has been specified.  Plot the data.
  name = "#plot_" + PCW.metric_index
  $ ->
    $(name).highcharts(params)
