// Modules
var http = require("http");
var url = require("url");
var fs = require('fs');
var node_static = require('node-static');
var AWS = require('aws-sdk');

// Load credentials to establish an https connection.
// options = {
//   key: fs.readFileSync('./security/privatekey.pem'),
//   cert: fs.readFileSync('./security/certificate.pem')
// }

// Create a static file server.  The 'node-static' community module makes life easier.
var file_server = new node_static.Server('./public');


/*////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
 This starts the block of code that controls internal server functions.
/////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////*/

// This is the main function to control the server's behavior.  All requests will
// enter here, so this is where routing happens.
function onIncoming(request, response) {

  // First, we sort requests based on the HTTP verb that's used.
  if (request.method == "GET")
  {
    // Static file serving.
    getRequests(request, response);
  }
  else if (request.method == "POST")
  {
    // Data is being passed to the server.
    postRequests(request, response)
  }
  else
  {
    // This verb is not supported on this server.  Respond with a "Bad Request" error.
    response.writeHead(400);
    response.write("Bad Request.  This HTTP verb is currently not supported.");
    response.end();
  }

}


function getRequests(request, response)
{
  // This function handles routing for requests that use the GET HTTP verb.  It makes
  // use of static file serving.

  // Parse the incoming request for the requested filename.
  var pathname = url.parse(request.url).pathname;

  if (pathname == "/")
  {
    // If the request is directed at the root of the app, respond with the main app page.
    file_server.serveFile("./views/main.html", 200, {}, request, response);
  }

  // Otherwise, respond with whatever file is being requested.
  request.addListener('end', function(){

    file_server.serve(request, response, function (error, result) {

      if (error)
      {
        // If this fails, respond with a 404 error code.
        response.writeHead(404);
        response.write(error.message);
        response.end();
      }
    });

  }).resume();
}


function postRequests(request, response)
{
  // This function handles routing for requests that use the POST HTTP verb.  Whenever
  // we need to pass data to the server, it comes through here.

  // Parse the incoming request for its pathname.
  var pathname = url.parse(request.url).pathname;



  if (pathname == "/login")
  {
    // Amazon AWS credentials are sent to the server via the POST verb.
    request.setEncoding('utf8')
    request.on('data', function(chunk) {

      // Chunk is a string that holds serialized credentials.
      var creds = chunk.split(",");
      AWS.config = {
        accessKeyId: creds[0],
        secretAccessKey: creds[1],
        region: creds[2],
        sslEnabled: true
      }

      // Now we can try to use the AWS module and hope everything works out.
      // Create handles for Amazon's Web Services.

      // Amazon Elastic Compute Cloud:
      var ec2 = new AWS.EC2();


      // There are a couple of things we need to grab.
      // 1) List of all active instances.
      // 2) List of all tags used in the account.
      // 3) List of tags associated with a single instance.

      // 1) and 3)
      ec2.describeInstances({}, function(error, data) {

        if (error)
        {
          // Send error response to browser.
          response.writeHead(502);
          response.write(error.message);
          response.end();
        }
        else
        {
          // The object "data" is structured and contains the response from Amazon.
          // Parse the object, pull out the instance names, and concatenate them
          // into a single string.  We do the same with the tags associated with those
          // instances.  I'm sorry the following structure kinda sucks for whoever reads this.
          var instance_list = "";
          var match_list = "";

          for (var i = 0; i < data.Reservations.length; i++)
          {
            for (var j = 0; j < data.Reservations[i].Instances.length; j++)
            {
              instance_list += data.Reservations[i].Instances[j].InstanceId;


              for (var k = 0; k < data.Reservations[i].Instances[j].Tags.length; k++)
              {
                match_list += data.Reservations[i].Instances[j].Tags[k].Key +
                ": " + data.Reservations[i].Instances[j].Tags[k].Value;

                if (k != data.Reservations[i].Instances[j].Tags.length - 1)
                {
                  match_list += ",";
                }
              }


              if (j != data.Reservations[i].Instances.length - 1)
              {
                instance_list += ",";
                match_list += ";";
              }
            }

            if (i != data.Reservations.length - 1)
            {
              instance_list += ",";
              match_list += ";";
            }
          }






          // 2)

          // Now, request Amazon for the tags.
          ec2.describeTags({}, function(error, data) {

            if (error)
            {
              // Send error response to browser.
              response.writeHead(502);
              response.write(error.message);
              response.end();
            }
            else
            {
              // The object "data" is structured and contains the response from Amazon.
              // Parse the object, pull out the tag names, and concatenate them into a single string.
              var tag_list = "";

              for (var i = 0; i < data.Tags.length; i++)
              {
                tag_list += data.Tags[i].Key + ": " + data.Tags[i].Value

                if (i != data.Tags.length - 1)
                {
                  tag_list += ",";
                }
              }


              // Combine these three strings.
              var response_string = instance_list + ";" + tag_list + ";" + match_list;

              // Return this string to the browser.
              response.writeHead(200);
              response.write(response_string);
              response.end();

            }

          });

        }

      });

    });
  }
  else if (pathname == "/pull_metrics")
  {
    // This function queries Amazon for time-sequenced data from the User's services.

    request.setEncoding('utf8')
    request.on('data', function(chunk) {

      // Chunk is a string that holds serialized parameters for our request to Amazon.
      var tokens = chunk.split(";");
      var time = tokens[0].split(",");

      // Create a handle to access Amazon services... Amazon CloudWatch utility.
      var cloudwatch = new AWS.CloudWatch();

      // Now we may create a parameter object, "params", that will placed in the
      // request function.  It specifies exactly what we are asking for.

      var params = {
        StartTime: String(time[0]),
        EndTime: String(time[1]),
        Period: String(time[2]),
        Namespace: 'AWS/EC2',
        MetricName: String(tokens[2]),
        Statistics: ['Average'],
        Dimensions: [
          {
            Name: 'InstanceId',
            Value: String(tokens[1])
          }
        ]
      };

      // Make the request to Amazon.
      cloudwatch.getMetricStatistics(params, function(error, data){
        if (error)
        {
          // Send error response to browser.
          response.writeHead(502);
          response.write(error.message);
          response.end();
        }
        else
        {
          // The object "data" is structured and contains the response from Amazon.

          // All we need to do is serialize the time-sequence data and send the string
          // back to the browser.
          var message = "";

          for (var i = 0; i < data.Datapoints.length; i++)
          {
            message += data.Datapoints[i].Timestamp + "," + data.Datapoints[i].Average;

            if (i < data.Datapoints.length - 1)
            {
              message += ";"
            }
          }

          // The string is complete.  Send it to the browswer for parsing.
          response.writeHead(200);
          response.write(message);
          response.end();

        }
      });
    });
  }


}


/*////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
 This ends the block of code that controls internal server functions.
/////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////*/


// Now, all that's left is to activate the server.
http.createServer(onIncoming).listen(3000);
