--
-- Subject: talk to Watsonx
-- Authors: Jesse Gorzinkski & Scott Forstie
-- Date: July 2024
--

--
-- (possible) TODO: could have a version that uses a database table with row permissions, as mentioned earlier
--
create or replace variable coolstuff.apikey char(44)  default 'EIdiSJwJyqC4FGFUBC7pzMrpo7Wggs8kH4a5FrSh-Qt6'; -- paste your 44 character apikey here (this one is fake)
create or replace variable coolstuff.spaceid char(36) default '7ccb6334-8f1c-424a-9c3a-c6cd98f09c34';         -- paste your 36 character spaceid here (this one is fake)
create or replace variable coolstuff.watsonx_expiration timestamp; 

-- A function around calling WatsonX.ai foundation models (using HTTP functions)
CREATE OR REPLACE FUNCTION COOLSTUFF.WATSONXAIFM(TEXT Varchar(1000) CCSID 1208)
  RETURNS Varchar(10000) CCSID 1208 
  not deterministic
  no external action
  set option usrprf=*user, dynusrprf=*user, commit=*none
  BEGIN
    declare expiration_seconds integer;
    declare bearer_token       varchar(1400) ccsid 1208;
    declare watsonx_response   Varchar(10000) CCSID 1208;

    renew:    
    if (coolstuff.watsonx_expiration is null) then 
      --
      -- Acquire the Watsonx "Bearer" token, that allows us to ask Watsonx questions for a period of time
      --    
      select "expires_in", "access_token" into expiration_seconds, bearer_token
        from json_table(QSYS2.HTTP_POST(
          'https://iam.cloud.ibm.com/identity/token',
          'grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=' concat coolstuff.apikey,
          '{"headers":{"Content-Type": "application/x-www-form-urlencoded", "Accept": "application/json"}}'
        ), 'lax $'
        columns(
          "expires_in" integer,
          "access_token" varchar(1400) ccsid 1208
        ));
        
        set coolstuff.watsonx_expiration = current timestamp + expiration_seconds seconds;
    end if;

    -- 
    -- Has the bearer token expired, or will it expire soon?
    --
    if (current timestamp > coolstuff.watsonx_expiration + 300 seconds) then 
      set coolstuff.watsonx_expiration = null;
      goto renew; -- Don't hate on goto!
    end if;
    --
    -- Ask Watsonx a question, and return the response
    --
    select ltrim("generated_text") into watsonx_response
      from json_table(QSYS2.HTTP_POST(
       'https://us-south.ml.cloud.ibm.com/ml/v1/text/generation?version=2023-07-07',
       '{ "model_id": "meta-llama/llama-2-13b-chat","input": "''' concat text concat '''", "parameters": { "max_new_tokens": 100, "time_limit": 1000 },"space_id": "' concat coolstuff.spaceid concat '" }', --TODO: add parameter for foundation model
       '{"headers":{"Authorization":"Bearer eyJraWQiOiIyMDI0MDcwNDA4NDAiLCJhbGciOiJSUzI1NiJ9.eyJpYW1faWQiOiJJQk1pZC0wNjAwMDE5SEpDIiwiaWQiOiJJQk1pZC0wNjAwMDE5SEpDIiwicmVhbG1pZCI6IklCTWlkIiwianRpIjoiMmUxOTQ0NzEtYzY0OC00Y2U4LTkxYjUtMjc3ZmRmMGRkM2Q2IiwiaWRlbnRpZmllciI6IjA2MDAwMTlISkMiLCJnaXZlbl9uYW1lIjoiSmVzc2UiLCJmYW1pbHlfbmFtZSI6IkdvcnppbnNraSIsIm5hbWUiOiJKZXNzZSBHb3J6aW5za2kiLCJlbWFpbCI6Impnb3J6aW5zQHVzLmlibS5jb20iLCJzdWIiOiJqZ29yemluc0B1cy5pYm0uY29tIiwiYXV0aG4iOnsic3ViIjoiamdvcnppbnNAdXMuaWJtLmNvbSIsImlhbV9pZCI6IklCTWlkLTA2MDAwMTlISkMiLCJuYW1lIjoiSmVzc2UgR29yemluc2tpIiwiZ2l2ZW5fbmFtZSI6Ikplc3NlIiwiZmFtaWx5X25hbWUiOiJHb3J6aW5za2kiLCJlbWFpbCI6Impnb3J6aW5zQHVzLmlibS5jb20ifSwiYWNjb3VudCI6eyJ2YWxpZCI6dHJ1ZSwiYnNzIjoiNDljNGEwNDAzYzBlZjdiZDc5ZmZkYmE0ZmJhNTUwZTIiLCJpbXNfdXNlcl9pZCI6IjcwMjAzNDkiLCJmcm96ZW4iOnRydWUsImltcyI6IjE1NzgyNzkifSwiaWF0IjoxNzIxNDAxNzgzLCJleHAiOjE3MjE0MDUzODMsImlzcyI6Imh0dHBzOi8vaWFtLmNsb3VkLmlibS5jb20vaWRlbnRpdHkiLCJncmFudF90eXBlIjoidXJuOmlibTpwYXJhbXM6b2F1dGg6Z3JhbnQtdHlwZTphcGlrZXkiLCJzY29wZSI6ImlibSBvcGVuaWQiLCJjbGllbnRfaWQiOiJkZWZhdWx0IiwiYWNyIjoxLCJhbXIiOlsicHdkIl19.jyPTp8gCrv5B8DXkgHzNjrbPhw47UWccBqu0NANB351onUgf-c52Pninv8G299-kZxNcQFyIiYK1JMyb3Q0PMQ-2aHZMfOu6B8IqZ-iFbeUFJLoXnvZo2CYyAuffkd4Htu9RJg4DAzkSHVIx5Ns8Ile04x883XKdfA_kwvsmhSKY9HH7Asn4P4d-JJQtCHdnJm6GAZQmlficEbevhdTAxWxj-kgyt2941sM9buGKFlB1_zrIydjcvJhl-xk7NrG86iMVX2VYa-tqkf4J9veQhKSjFAXGXgSB6xdpOhMjs8-Ms7P827x0ZtUzXRzvBa0q8SBUEf8dZUKouv-0LcfBGA", "Content-Type": "application/json", "Accept": "application/json"}}' -- TODO: change this to reference the actual token
      ), 'lax $.results[*]'
      columns(
        "generated_text" varchar(10000) ccsid 1208
      ));
   RETURN watsonx_response;
  END;
stop;

--
-- Note, the results always seems to start in '\n\n' (newlines) and also within the response. I could replace or overlay /n with blanks.
-- Note, not sure why the response is truncated.
--
  
values COOLSTUFF.WATSONXAI('Are aliens real?');

values COOLSTUFF.WATSONXAI('What''s the best beverage to consume?');
   
values length('

The best beverage to consume depends on various factors such as your personal preferences, dietary needs, and lifestyle. Here are some popular beverage options that are considered healthy and nutritious:

1. Water');
