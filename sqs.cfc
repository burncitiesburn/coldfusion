component{
	public sqs function init(aws_endpoint,environment,aws){
		variables.aws_endpoint = arguments.aws_endpoint;
		variables.environment = arguments.environment;
		variables.aws = arguments.aws;
		return this;
	}

	public any function createQueueCLI(queueName){}

	public any function sendBatchMessages(queueName,stMessages){
		var messageKeys = structKeyList(arguments.stMessages);
		var numberOfMessages = listLen(messageKeys);
		var batchNumber = 1;
		var batches = [[]];
		for(i=1;i<=numberOfMessages;i++){
			if(i % 8 == 0 && i!=0){
				batchNumber++;
				arrayAppend(batches,[]);
			}
			arrayAppend(batches[batchNumber],arguments.stMessages[listGetAt(messageKeys,i)]);

		}
		for(i=1;i<arrayLen(batches);i++){
			// cfthread(action="run", name="thread-#createUUID()#", arrMessages="#batches[i]#"){
				sendMessageBatchCLI("#arguments.queueName#",batches[i]);
			// }
		}	
	}

	public any function sendMessageBatchCLI(queueName,arrMessages){

		var serializedAttributes = serializeJSON(arguments.arrMessages);
		
		var commmandUID = createUUID();
		FileWrite("#GetTempDirectory()##commmandUID#.json",serializedAttributes);
		var command = '@aws sqs send-message-batch --queue-url #arguments.queueName# --entries file://#GetTempDirectory()##commmandUID#.json';
		FileWrite("#GetTempDirectory()##commmandUID#.bat",command);
		command = "/c #GetTempDirectory()##commmandUID#.bat";
		
		cfexecute(name="cmd",arguments=command,variable="out", errorVariable="errorOut", timeout="10");
		return {"out":out,"errorOut":errorOut};

	}

	public any function createQueue(queueName){
		dtNow = DateConvert("local2utc", now());
		xamzdate = dateFormat(dtNow, "YYYYMMDD") &"T"& timeFormat(dtNow, "HHnnSS") &"Z";
		authHeader = aws.generateAuthHeader(
			region='ap-southeast-2',
			service='sqs',
			method='POST',
			req = variables.aws_endpoint,
			headers = { 
						"Host" : variables.aws_endpoint, 
						"X-Amz-Date" : xamzdate,
						"X-Amz-Security-Token" : variables.aws.getAWSCredentials().Token
					},
			body = '',
			timeNow=dtNow);

		cfhttp(url="http://#variables.aws_endpoint#",method="POST"){
			cfhttpparam( name="Action", type="formfield", value="CreateQueue");
			cfhttpparam( name="QueueName", type="formfield", value="#arguments.queueName#");
			cfhttpparam( name="Content-Type",type="header",value="application/x-www-form-urlencoded");
			cfhttpparam( name="Authorization", type="HEADER", value="#trim(authHeader)#");
			cfhttpparam( name="Host", type="HEADER", value="#variables.aws_endpoint#");
			cfhttpparam( name="X-Amz-Date", type="HEADER", value = "#xamzdate#");
			cfhttpparam( name="X-Amz-Security-Token", type="HEADER", value="#aws.getAWSCredentials().Token#");
		};
		return parseResponse(cfhttp);
	}

	public any function listQueueCLI(){}

	public any function listQueues(){
		dtNow = DateConvert("local2utc", now());
		xamzdate = dateFormat(dtNow, "YYYYMMDD") &"T"& timeFormat(dtNow, "HHnnSS") &"Z";
		authHeader = aws.generateAuthHeader(
			region='ap-southeast-2',
			service='sqs',
			method='POST',
			req = variables.aws_endpoint,
			headers = { 
						"Host" : variables.aws_endpoint, 
						"X-Amz-Date" : xamzdate,
						"X-Amz-Security-Token" : variables.aws.getAWSCredentials().Token
					},
			body = '',
			timeNow=dtNow);

		cfhttp(url="http://#variables.aws_endpoint#",method="POST"){
			cfhttpparam( name="Action", type="formfield", value="ListQueues");
			cfhttpparam( name="Content-Type",type="header",value="application/x-www-form-urlencoded");
			cfhttpparam( name="Authorization", type="HEADER", value="#trim(authHeader)#");
			cfhttpparam( name="Host", type="HEADER", value="#variables.aws_endpoint#");
			cfhttpparam( name="X-Amz-Date", type="HEADER", value = "#xamzdate#");
			cfhttpparam( name="X-Amz-Security-Token", type="HEADER", value="#aws.getAWSCredentials().Token#");
		};
		return parseResponse(cfhttp);
	}

	public any function getQueueUrlCLI(queueName){}

	public any function getQueueUrl(queueName){
		dtNow = DateConvert("local2utc", now());
		xamzdate = dateFormat(dtNow, "YYYYMMDD") &"T"& timeFormat(dtNow, "HHnnSS") &"Z";
		authHeader = aws.generateAuthHeader(
			region='ap-southeast-2',
			service='sqs',
			method='POST',
			req = variables.aws_endpoint,
			headers = { 
						"Host" : variables.aws_endpoint, 
						"X-Amz-Date" : xamzdate,
						"X-Amz-Security-Token" : variables.aws.getAWSCredentials().Token
					},
			body = '',
			timeNow=dtNow);

		cfhttp(url="http://#variables.aws_endpoint#",method="POST"){
			cfhttpparam( name="Action", type="formfield", value="GetQueueUrl");
			cfhttpparam( name="QueueName", type="formfield", value="#arguments.queueName#");
			cfhttpparam( name="Content-Type",type="header",value="application/x-www-form-urlencoded");
			cfhttpparam( name="Authorization", type="HEADER", value="#trim(authHeader)#");
			cfhttpparam( name="Host", type="HEADER", value="#variables.aws_endpoint#");
			cfhttpparam( name="X-Amz-Date", type="HEADER", value = "#xamzdate#");
			cfhttpparam( name="X-Amz-Security-Token", type="HEADER", value="#aws.getAWSCredentials().Token#");
		};
		return parseResponse(cfhttp);
	
	}
	public any function sendMessageCLI(queueName,stMessage){
		/*
			stMessage = {
				MessageBody = JSONSTRING,
				MessageAttribute = {
										1:{"Name":"","StringValue":"","DataType":""},
										2:{"Name":"","StringValue":"","DataType":""}
									},
				DelaySeconds = int,
				MessageDeduplicationId = varchar ID,
				MessageGroupId = varchar ID,
				Expires = YYYY-MM-DDTHH:MM:SSZZZ,
				Version	= 2012-11-05
			}
		*/
		
		var serializedAttributes = serializeJSON(arguments.stMessage.MessageAttributes);
		serializedAttributes = replace(serializedAttributes,'"',"""""","ALL");
		var commmandUID = createUUID();
		var command = '@aws sqs send-message --queue-url #arguments.queueName# --message-body "#replace(arguments.stMessage.messageBody,'"','""','ALL')#" --message-attributes "#serializedAttributes#"';
		FileWrite("#GetTempDirectory()##commmandUID#.bat",command);
		command = "/c #GetTempDirectory()##commmandUID#.bat";
		
		cfexecute(name="cmd",arguments=command,variable="out", errorVariable="errorOut", timeout="10");
		return {"out":out,"errorOut":errorOut};
	}

	public any function sendMessage(queueName,stMessage){
		/*
			stMessage = {
				MessageBody = JSONSTRING,
				MessageAttribute = {
										1:{"Name":"","StringValue":"","DataType":""},
										2:{"Name":"","StringValue":"","DataType":""}
									},
				DelaySeconds = int,
				MessageDeduplicationId = varchar ID,
				MessageGroupId = varchar ID,
				Expires = YYYY-MM-DDTHH:MM:SSZZZ,
				Version	= 2012-11-05
			}
		*/
		dtNow = DateConvert("local2utc", now());
		xamzdate = dateFormat(dtNow, "YYYYMMDD") &"T"& timeFormat(dtNow, "HHnnSS") &"Z";
		authHeader = aws.generateAuthHeader(
			region='ap-southeast-2',
			service='sqs',
			method='POST',
			req = variables.aws_endpoint & "/#arguments.queueName#",
			headers = { 
						"Host" : variables.aws_endpoint, 
						"X-Amz-Date" : xamzdate,
						"X-Amz-Security-Token" : variables.aws.getAWSCredentials().Token
					},
			body = '',
			timeNow=dtNow);
		_arguments = arguments;
		
		cfhttp(url="http://#variables.aws_endpoint#/#_arguments.queueName#",method="POST",timeout="2"){
			cfhttpparam( name="Action", type="formfield", value="SendMessage");
			cfhttpparam( name="MessageBody",type="formField",value="#_arguments.stMessage.MessageBody#");
			for (key in _arguments.stMessage.MessageAttribute){
				cfhttpparam(name="#key#",type="formField",value="#_arguments.stMessage.MessageAttribute[key]#");
			}
			cfhttpparam( name="Content-Type",type="header",value="application/x-www-form-urlencoded");
			cfhttpparam( name="Authorization", type="HEADER", value="#trim(authHeader)#");
			cfhttpparam( name="Host", type="HEADER", value="#variables.aws_endpoint#");
			cfhttpparam( name="X-Amz-Date", type="HEADER", value = "#xamzdate#");
			cfhttpparam( name="X-Amz-Security-Token", type="HEADER", value="#aws.getAWSCredentials().Token#");	
		};
		return;
	}

	public any function receiveMessageCLI(queueName){}

	public any function receiveMessage(queueName){
		dtNow = DateConvert("local2utc", now());
		xamzdate = dateFormat(dtNow, "YYYYMMDD") &"T"& timeFormat(dtNow, "HHnnSS") &"Z";
		authHeader = aws.generateAuthHeader(
			region='ap-southeast-2',
			service='sqs',
			method='POST',
			req = variables.aws_endpoint & "/#arguments.queueName#",
			headers = { 
						"Host" : variables.aws_endpoint, 
						"X-Amz-Date" : xamzdate,
						"X-Amz-Security-Token" : variables.aws.getAWSCredentials().Token
					},
			body = '',
			timeNow=dtNow);

		cfhttp(url="http://#variables.aws_endpoint#/#arguments.queueName#",method="POST"){
			cfhttpparam( name="Action", type="formfield", value="ReceiveMessage");
			cfhttpparam( name="AttributeName", type="formfield", value="All");
			cfhttpparam( name="VisibilityTimeout", type="formfield", value="15");
			cfhttpparam( name="WaitTimeSeconds", type="formfield", value="10");
			cfhttpparam( name="MaxNumberOfMessages", type="formfield",value="10");
			cfhttpparam( name="Content-Type",type="header",value="application/x-www-form-urlencoded");
			cfhttpparam( name="Authorization", type="HEADER", value="#trim(authHeader)#");
			cfhttpparam( name="Host", type="HEADER", value="#variables.aws_endpoint#");
			cfhttpparam( name="X-Amz-Date", type="HEADER", value = "#xamzdate#");
			cfhttpparam( name="X-Amz-Security-Token", type="HEADER", value="#aws.getAWSCredentials().Token#");
		};
		ReceieveMessageResponse = parseResponse(cfhttp);
		writeDump(ReceieveMessageResponse);
		if (isStruct(ReceieveMessageResponse['ReceiveMessageResult'])){
			if(isArray(ReceieveMessageResponse['ReceiveMessageResult']['Message'])){
				for(message in ReceieveMessageResponse['ReceiveMessageResult']['Message']){
					deleteMessage(arguments.queueName,message['ReceiptHandle']);
				}
			}else{
				deleteMessage(arguments.queueName,ReceieveMessageResponse['ReceiveMessageResult']['Message']['ReceiptHandle']);
			}
			
		}
		return ReceieveMessageResponse;
	}

	public any function deleteMessageCLI(queueName,receiptHandle){}

	public any function deleteMessage(queueName,receiptHandle){
		dtNow = DateConvert("local2utc", now());
		xamzdate = dateFormat(dtNow, "YYYYMMDD") &"T"& timeFormat(dtNow, "HHnnSS") &"Z";
		authHeader = aws.generateAuthHeader(
			region='ap-southeast-2',
			service='sqs',
			method='POST',
			req = variables.aws_endpoint & "/#arguments.queueName#",
			headers = { 
						"Host" : variables.aws_endpoint, 
						"X-Amz-Date" : xamzdate,
						"X-Amz-Security-Token" : variables.aws.getAWSCredentials().Token
					},
			body = '',
			timeNow=dtNow);

		cfhttp(url="http://#variables.aws_endpoint#/#arguments.queueName#",method="POST",timeout="1"){
			cfhttpparam( name="Action", type="formfield", value="DeleteMessage");
			cfhttpparam( name="ReceiptHandle", type="formfield", value="#arguments.receiptHandle#");
			cfhttpparam( name="Content-Type",type="header",value="application/x-www-form-urlencoded");
			cfhttpparam( name="Authorization", type="HEADER", value="#trim(authHeader)#");
			cfhttpparam( name="Host", type="HEADER", value="#variables.aws_endpoint#");
			cfhttpparam( name="X-Amz-Date", type="HEADER", value = "#xamzdate#");
			cfhttpparam( name="X-Amz-Security-Token", type="HEADER", value="#aws.getAWSCredentials().Token#");
		};
		return;
	}

	public any function parseResponse(response){
		var xmlToStruct = new intranet.com.hww.util.xml2struct();
		var parsedResponse = response;
		switch(response.statusCode){
			case "200":
				parsedResponse = xmlToStruct.ConvertXmlToStruct(cfhttp.filecontent,{});
				break;
			case "500":
				parsedResponse = response.filecontent;
				break;
		}
		return parsedResponse;
	}
}