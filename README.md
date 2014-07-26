The Panda Panopticon
=====================

__Copyright (c) 2014 PandaStrike__

__Contributors:__
- David Harper <david@pandastrike.com>
- Lance Lakey  <lance@pandastrike.com>

This software is released under the MIT License.

Overview
--------
Panda Panopticon is a lightweight Amazon Web Services (AWS) CloudWatch dashboard, and it lets you see it all.  This app is anchored by a proxy server, implemented in Node.js.  The server makes use of the AWS Node SDK to pull data from Amazon and pipe it to the client.  The client offers a graphical user interface (GUI) constructed from Polymer elements.  Data is processed in-browser using JavaScript and plotted using the HighCharts JavaScript library.  User credentials and data are protected through end-to-end encryption.


<img src="https://raw.github.com/pandastrike/panda-panopticon/master/ReadmeImages/Overview.png">
-> Overview of application structure.


User Experience
----------------
Overall, the GUI is minimalist.  On loading, click "AWS Login" and simply enter your account's:
- (1) Access Key ID,
- (2) Secret Access Key,
- (3) Region (Currently, only one region at a time is supported).

<img src="https://raw.github.com/pandastrike/panda-panopticon/master/ReadmeImages/Login.png">
-> Screenshot of Login.

Upon successful login, two new buttons will appear.  Let's start with "Options".

This pulls up a dialog box that lets you customize your query to Amazon.  The first tab contains time controls.  You may request data from as far back as two weeks.  You also have control over the reporting time-resolution, however, there are restrictions.  Amazon will not accept requests that return greater than 1,440 data points, so make sure Time / Resolution < 1,440.  Also, resolutions finer than 5 minutes are only available to those that paid Amazon for this extra service.

<img src="https://raw.github.com/pandastrike/panda-panopticon/master/ReadmeImages/Time.png">
-> Screenshot of time tab

The next tab controls the source of the data.  All instances and tags currently associated with your account, as of your login, are auto-discovered and displayed here, alphabetically.  You may select one or more instances by their ID(s).  Or, you may instead select one or more tag name(s), and the appropriate instances will be pulled.    This list is currently not updated automatically, so if any new ones are created, you will need to logout and log back in.

<img src="https://raw.github.com/pandastrike/panda-panopticon/master/ReadmeImages/Filter.png">
-> Screenshot of instance/tag tab

The final tab controls what data is pulled for each instance.  You may select one or more of the metrics displayed.  Each metric will be plotted separately.

<img src="https://raw.github.com/pandastrike/panda-panopticon/master/ReadmeImages/Metric.png">
-> Screenshot of metric tab



With your options set, we can finally push the "Pull Metrics" Button.  Depending on how many instances are being analyzed, this might take a while.  But, you can see your progress displayed as data is pulled down.  Each metric gets its own plot, and these plots take up the whole window.

If you hover your cursor over a plot, you will notice a tooltip appears.  This helpful feature gives you detailed information on the instance you're examining.  You have access to detailed timestamp and tagging information, right there in the plot.  So, go forth and see it for yourself!!

<img src="https://raw.github.com/pandastrike/panda-panopticon/master/ReadmeImages/Plot.png">
-> Screenshot of plot demo



Nuts and Bolts
---------------
Technologies used in Panda Panopticon:
- Node.js <http://www.nodejs.org>
- Node Community Modules: 'aws-sdk', 'key-forge', 'node-static'
- Polymer <http://www.polymer-project.org>
- HighCharts <http://http://www.highcharts.com/>

The Panda Panopticon consists of a user-facing client and proxy server to secure credentials and prevent cross-origin requests.  You can see a more detailed description of both below, but first let's cover how to get this up and running for your own testing.


__Getting Setup:__

- (1) Make sure you have Node installed.
- (2) Download this repository onto your computer or server.
- (3) You'll need to place private key and a security certificate in the "security" folder.  You can get these from a trusted cert authority, or if you want to test for free, you can use OpenSSL.  These three commands will do the trick:

`openssl genrsa -out privatekey.pem 1024
openssl req -new -key privatekey.pem -out certrequest.csr
openssl x509 -req -in certrequest.csr -signkey privatekey.pem -out certificate.pem`

- (4) You should be ready to go.  Activate the server with the following:

`node server.js`

- (5) Now, direct your browser to the IP address of the remote server, or 'localhost' if you are testing this on your personal machine.  Panopticon will force an HTTPS connection, and you should see a web page ready to accept your AWS login.  Enjoy!!

 

__Proxy Server:__
This is relatively lightweight and implemented in vanilla Node.  The client-to-server connection is secured by forcing HTTPS protocol.  When pulling data from Amazon, the 'aws-sdk' module offers SSL protection within its API calls.  Basic files for the app use GET requests to the server and are fulfilled with simple static serving, implemented by the 'node-static' module.  

Logging in and requesting data are sent as POST requests for more specialized handling.  After successful login, the sever will assign a unique random token to the client for identification.  Credentials are stored on the server for 24 hours and pulled when presented with the correct token.  Credentials are *not* stored within the client.

__Client:__
This is the main user interface.  Buttons and other elements on-screen are powered by Google's Polymer elements.  JavaScript for the client page is generated from CoffeeScript.  Seek the *.coffee file for annotated code.

After logging in, the credentials are removed from memory and the input fields as a security precaution.  The server returns a token that is used for identification in their place.  The "Options" dialog is programmatically populated with instance IDs and tag names.  

When the "Pull Metrics" button is pressed, the client makes a sequence of calls to the server, making one request per instance per metric.  This is done to maximize the number of data points that can be pulled from Amazon.  Each response is parsed and sorted.  Activity on each metric is displayed to the user using a progress bar.  

When all the data for a single metric is collected, the HighCharts library is called to generate a plot.  The data must conform to a specific format to display correctly.  Special formatting was also employed on the plots' tooltip to display detail timestamp and tag associations.
