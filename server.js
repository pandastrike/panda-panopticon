// Modules
var https = require("https");
var http = require("http");
var url = require("url");
var fs = require('fs');
var node_static = require('node-static');
var AWS = require('aws-sdk');
var randomKey = require('key-forge').randomKey;




// Load HTTPS private key and certificate.
// These files are used by the 'https' core module to establish a secure connection.
options = {
  key: fs.readFileSync('./security/privatekey.pem'),
  cert: fs.readFileSync('./security/certificate.pem')
}


// Create a static file server.  The 'node-static' community module makes life easier.
var file_server = new node_static.Server('./public');


// Create an array to store unique User session objects.
var UserSessions = [];

// We will generate unique, pseudo-random tokens to identify Users.  The 'key-forge' community module makes life easier.
// Set the byte length of this token.
var key_size = 32;



/*////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
 This starts the block of code that controls internal server functions.
/////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////*/


// This server uses HTTPS to communicate with the browswer.  If the User requests an
// unsecured http connection, we need to reroute and default them to the https port.
// This function will sit on port 80 and direct traffic to where it belongs.

function OnUnsecuredRequest(request, response) {

  // Direct to the same pathname on port 443 for an https connection.
  var host = request.headers.host;
  var path = url.parse(request.url).pathname;
  var new_url = "https://" + host + path;

  response.writeHead(301,
    {"Location" : new_url }
  );


  response.end();
}



// This is the main function to control the server's behavior.  All https requests will
// enter here, so this is where main routing happens.
function OnRequest(request, response) {

  // First, we sort requests based on the HTTP verb that's used.
  if (request.method == "GET")
  {
    // Static file serving.
    getRequests(request, response);
  }
  else if (request.method == "POST")
  {
    // Data is being passed to the server.  This is where the calls for Amazon data go.
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
        // // If this fails, respond with a 404 error code.
        // response.writeHead(404);
        // response.write(error.message);
        // response.end();
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
    // Amazon AWS credentials are sent to the server.  We need to associate them with a User token
    // and store the credentials here, where they are safe.

    // Pull the data from the request.
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

      // This is a new User, so we need to create a new token using the 'key-forge' module.
      // This key is not packaged until we confirm the AWS credientals are valid.
      var generated_token = GenerateToken();



      // Next, we confirm the credientials are valid.  All we need to do is try to use the
      // AWS module and see if everything works out.

      // Handle for Amazon Elastic Compute Cloud:
      var ec2 = new AWS.EC2();


      // There are a couple of things we need to grab.
      // 1) List of all active instances.
      // 2) List of all tags used in the account.
      // 3) List of tags associated with a single instance.
      //
      // These will be collected and sub-strings and then put together just before
      // we reply to the client.


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
          // instances.  The following structure is kinda shitty, but it works.

          // The goal is to complete these two substrings (that fullfill goals 1 and 3 from above).
          var instance_list = "";
          var match_list = "";

          // instance_list is a comma delimited list of instance IDs.
          // math_list is a semi-colon delimited list of tag names associated with each instance.
          // Since multiple tag names are assigned to a given instance, these are separated by commas.
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
              // This fulfills goal 2 from our list above.
              var tag_list = "";

              for (var i = 0; i < data.Tags.length; i++)
              {
                tag_list += data.Tags[i].Key + ": " + data.Tags[i].Value

                if (i != data.Tags.length - 1)
                {
                  tag_list += ",";
                }
              }


              // We are almost ready to send a reply to the client.  Now that they have been validated,
              // we need to store these AWS credientials and the unique token used to identify the User.
              temp = {
                token: generated_token.token,
                expiration: generated_token.expiration,
                credentials: AWS.config
              };

              UserSessions.push(temp);

              // Build the response string from the token and other substrings.
              var response_string = generated_token.token + ";" + instance_list + ";" + tag_list + ";" + match_list;

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

    // Pull the data from the request.
    request.setEncoding('utf8')
    request.on('data', function(chunk) {

      // Chunk is a string that holds serialized parameters for our request to Amazon.
      var mini_chunks = chunk.split(";");
      var token = mini_chunks[0];
      var time = mini_chunks[1].split(",");

      // Before we go any further, we must determine who is requesting data so we can query the
      // appropriate Amazon account.  When the User logged in, this server generated a unique
      // token and passed it to the browser.  We look for this token now.
      var token_found = false;
      for (var i = 0; i < UserSessions.length; i++)
      {
        if (UserSessions[i].token == token)
        {
          // The User Token has been found.
          token_found = true;

          // Load the stored credientials into the AWS module.
          AWS.config = UserSessions[i].credentials

          break;
        }
      }

      if (token_found == false)
      {
        // The token has either expired or something fishy is going on.
        // We refuse this request. Send response to browser.
        response.writeHead(401);
        response.write("Access Denied:  Security clearance has expired or is invalid.");
        response.end();
        return;
      }

      // Create a handle to access Amazon services... Amazon CloudWatch utility.
      var cloudwatch = new AWS.CloudWatch();

      // Now we may create a parameter object, "params", that will placed in the
      // request function.  It specifies exactly what we are asking for.

      var params = {
        StartTime: String(time[0]),
        EndTime: String(time[1]),
        Period: String(time[2]),
        Namespace: 'AWS/EC2',
        MetricName: String(mini_chunks[3]),
        Statistics: ['Average'],
        Dimensions: [
          {
            Name: 'InstanceId',
            Value: String(mini_chunks[2])
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


function GenerateToken()
{
  var temp_token = randomKey(key_size);

  // Ensure this token is unique.
  var is_unique = false;
  while (is_unique == false)
  {
    is_unique = true;

    for (var i = 0; i < UserSessions.length; i++)
    {
      if (UserSessions[i].token == temp_token)
      {
        // Against long odds, this key is a repeat of one already stored.  Try again.
        temp_token = randomKey(key_size);
        is_unique = false;
        break;
      }
    }
  }

  // Next, we set an expiration for this token, one day from now.
  d = new Date();
  expiration = d.getTime();
  expiration += 24 * 60 * 60 * 1000;

  return {
    token: temp_token,
    expiration: expiration
  };
}


function ClearExpiredTokens()
{
  // This function keeps the array "UserSessions" clean.  Tokens are given a 24 hour lifetime,
  // partially for security and partially to keep storage needs to minimum.

  d = new Date();
  current_time = d.getTime();

  // Cycle through the tokens and prune any that have expired.
  var total_cycles = UserSessions.length;
  var adjustment = 0;

  for (var i = 0; i < total_cycles; i++)
  {
    if (UserSessions[i + adjustment].expiration < current_time)
    {
      // Prune
      UserSessions.splice(i + adjustment, 1);

      // Be careful.  Since we deleted an element in this array, we need to adjust the
      // index we use to target the next element.
      adjustment--;
    }
  }


  // With the pruning complete, we wait another hour and prune again.  This function
  // recursively calls itself for eternity.
  callback = function() {
    ClearExpiredTokens();
  };

  prune_id = setTimeout(callback, 60 * 60 * 1000);
}



/*////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////
 This ends the block of code that controls internal server functions.
/////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////*/


// Now, all that's left is to activate the server.
https.createServer(options, OnRequest).listen(443);

// Start the server that listens on unsecured http, so it can redirect.
http.createServer(OnUnsecuredRequest).listen(80);

// And start the recursive function for token pruning.
ClearExpiredTokens();
