
create schema watsonx;
create or replace variable watsonx.apikey varchar(100)  default '';
create or replace variable watsonx.spaceid varchar(100) default '';
create or replace variable watsonx.JobBearerToken varchar(10000) default null;
create or replace variable watsonx.JobTokenExpires timestamp;

--
-- (possible) TODO: could have a version that uses a database table with row permissions, as mentioned earlier
--

create or replace procedure watsonx.SetApiKeyForJob(apikey varchar(100))
begin
  set watsonx.apikey = apikey;
end;

create or replace procedure watsonx.SetSpaceIdForJob(spaceid varchar(100))
begin
  set watsonx.spaceid = spaceid;
end;

create or replace procedure watsonx.SetBearerTokenForJob(bearer_token varchar(10000), expires integer)
modifies sql data
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
modifies sql data
begin
  set watsonx.JobBearerToken = null;
  set watsonx.JobTokenExpires = null;
end;