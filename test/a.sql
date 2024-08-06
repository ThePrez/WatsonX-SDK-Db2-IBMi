------
-- Ensure authenticate can return Y (success)
------

call watsonx.logoutjob();
call watsonx.setapikeyforjob('');
call watsonx.setspaceidforjob('');

-- Should return Y
values watsonx.ShouldGetNewToken();

-- Should return Y
values watsonx.authenticate();

-- Should return N
values watsonx.ShouldGetNewToken();

values watsonx.generate('Hello world');

------
-- Ensure authenticate can return N (failed)
------

call watsonx.logoutjob();
call watsonx.setapikeyforjob('-BAD');

-- Should return Y
values watsonx.ShouldGetNewToken();

-- Should return N
values watsonx.authenticate();

-- Should return Y
values watsonx.ShouldGetNewToken();

-- Should return '*PLSAUTH'
values watsonx.generate('Hello world');