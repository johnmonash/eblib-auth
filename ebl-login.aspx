<%@ Page Language="C#"%>
<%@ Import Namespace="System.Security.Cryptography" %>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="utf-8" />
        <title></title>
    </head>
    <body>
        <div>
<%
// requires the following XML fragment to be included in the web.config file:
// <roleManager enabled="true" defaultProvider="AspNetWindowsTokenRoleProvider"/>

	string AllowedGroup = @"YOURDOMAIN\SomeGroup"; //replace with AD group that is allowed access
	string destination = "http://your.eblib-url.eblib.com.au"; //replace with your eblib URL
	string sharedsecret = "REPLACEME"; //replace with the EBLIB shared secret
	string patrontype = ""; //May need to source this from AD at a later stage?

	//Check if AllowedGroup has been set, and user is a member
	if (AllowedGroup != "" && Roles.IsUserInRole(AllowedGroup)) {
		if (User.Identity.IsAuthenticated) {
			string user = User.Identity.Name;
			SHA1 sha = new SHA1CryptoServiceProvider(); 

			//Make SHA1 hash of the user ID
			byte[] userHashBytes = sha.ComputeHash(Encoding.UTF8.GetBytes(user));
			string userHash = BitConverter.ToString(userHashBytes).Replace("-", string.Empty);

			int epoch = (int)(DateTime.UtcNow - new DateTime(1970, 1, 1)).TotalSeconds;

			destination += "?"; //Add "?" to prepare for query
			//if destination url specified in the query string, use that instead
			string url = HttpContext.Current.Request.Url.AbsoluteUri;
			string [] split = url.Split(new char[] {'?'},2);
			if (split.Length == 2) { 
				if (split[1].Substring(0,4).CompareTo("url=") == 0) {
					destination = split[1].Substring(4) + "&"; //Add "&" to prepare for rest of query
				}
			}

			//Make SHA1 hash of the data
			string data = userHash + epoch + sharedsecret + patrontype;
			byte[] result = sha.ComputeHash(Encoding.UTF8.GetBytes(data));
			string hash = BitConverter.ToString(result).Replace("-", string.Empty);
			
			destination += "userid=" + userHash + "&tstamp=" + epoch + "&id=" + hash;
			if (patrontype != "") { //only add patrontype to query if it has been specified
				destination += "&patrontype=" + patrontype;
			}
			Response.Write("Redirecting; if this doesn't work, click <a href=\"" + destination + "\">here</a>");
			Response.Redirect(destination);
		} else {
			Response.Write("You are not logged in. Please close the browser window, then try again. If problem persists, please contact your servicedesk.");
		}
	} else {
		Response.Write("You are not authorised to use this service. If you believe this is in error, please contact your servicedesk.");
	}

%>
        </div>
        
    </body>
</html>
