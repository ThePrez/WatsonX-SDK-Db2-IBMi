create or replace function watsonx.generate(text varchar(1000) CCSID 1208)
  returns varchar(10000) ccsid 1208
  not deterministic
begin
  declare watsonx_response Varchar(10000) CCSID 1208;
  declare needsNewToken char(1) default 'Y';

  set needsNewToken = watsonx.ShouldGetNewToken();
  if (needsNewToken = 'Y') then
    return '*PLSAUTH';
  end if;

  -- TODO: consider using verbose to we can capture errors
  -- TODO: store the result into a response variable, then parse after
  select ltrim("generated_text") into watsonx_response
  from json_table(QSYS2.HTTP_POST(
    'https://us-south.ml.cloud.ibm.com/ml/v1/text/generation?version=2023-07-07',
    json_object('model_id': 'meta-llama/llama-2-13b-chat', 'input': text, 'parameters': json_object('max_new_tokens': 100, 'time_limit': 1000), 'space_id': watsonx.spaceid), --TODO: add parameter for foundation model
    json_object('headers': json_object('Authorization': 'Bearer ' concat watsonx.JobBearerToken, 'Content-Type': 'application/json', 'Accept': 'application/json')) 
  ), 'lax $.results[*]'
  columns(
    "generated_text" varchar(10000) ccsid 1208
  ));

  if (watsonx_response is null) then
    return '*ERROR';
  end if;
  
  return watsonx_response;
end;