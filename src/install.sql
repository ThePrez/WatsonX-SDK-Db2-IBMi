
create schema watsonx;
create or replace variable watsonx.region varchar(16) ccsid 1208 default 'us-south';
create or replace variable watsonx.apiVersion varchar(10) ccsid 1208 default '2023-07-07';
create or replace variable watsonx.apikey varchar(100) ccsid 1208 default '';
create or replace variable watsonx.spaceid varchar(100) ccsid 1208 default '';
create or replace variable watsonx.JobBearerToken varchar(10000) ccsid 1208 default null;
create or replace variable watsonx.JobTokenExpires timestamp;

create or replace function watsonx.GetUrl(route varchar(1000))
  returns varchar(256) ccsid 1208
begin
  declare finalUrl varchar(256) ccsid 1208;

  set finalUrl = 'https://' concat watsonx.region concat '.ml.cloud.ibm.com/ml/v1' concat route;

  if (watsonx.apiVersion is not null and watsonx.apiVersion != '') then
    set finalUrl = finalUrl concat '?version=' concat watsonx.apiVersion;
  end if;

  return finalUrl;
end;

create or replace procedure watsonx.SetApiKeyForJob(apikey varchar(100))
  program type sub
  set option usrprf = *user, dynusrprf = *user, commit = *none
begin
  set watsonx.apikey = apikey;
end;

create or replace procedure watsonx.SetSpaceIdForJob(spaceid varchar(100))
  program type sub
  set option usrprf = *user, dynusrprf = *user, commit = *none
begin
  set watsonx.spaceid = spaceid;
end;

create or replace procedure watsonx.SetBearerTokenForJob(bearer_token varchar(10000), expires integer)
  modifies sql data
  program type sub
  set option usrprf = *user, dynusrprf = *user, commit = *none
begin
  set watsonx.JobBearerToken = bearer_token;
  -- We subtract 60 seconds from the expiration time to ensure we don't cut it too close
  set watsonx.JobTokenExpires = current timestamp + expires seconds - 60 seconds;
end;

create or replace function watsonx.ShouldGetNewToken() 
  returns char(1)
begin
  if (watsonx.JobBearerToken is null) then
    return 'Y';
  end if;
  if (watsonx.JobTokenExpires is null) then
    return 'Y';
  end if;
  if (current timestamp > watsonx.JobTokenExpires) then
    return 'Y';
  end if;
  return 'N';
end;

create or replace procedure watsonx.logoutJob()
  set option usrprf = *user, dynusrprf = *user, commit = *none
  program type sub
  modifies sql data
begin
  set watsonx.JobBearerToken = null;
  set watsonx.JobTokenExpires = null;
end;