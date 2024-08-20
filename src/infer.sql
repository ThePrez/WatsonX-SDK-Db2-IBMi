-- https://cloud.ibm.com/apidocs/watsonx-ai#deployments-text-generation
-- TODO: needs test case
create or replace function watsonx.InferText(
  id_or_name varchar(1000) ccsid 1208,
  text varchar(1000) ccsid 1208
)
  returns varchar(10000) ccsid 1208
  not deterministic
  no external action
  set option usrprf = *user, dynusrprf = *user, commit = *none
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
    watsonx.geturl('/' concat id_or_name concat '/text/generation'),
    json_object('input': text, 'parameters': json_object('max_new_tokens': 100, 'time_limit': 1000), 'space_id': watsonx.spaceid),
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

