
create or replace procedure watsonx.GetModels()
  DYNAMIC RESULT SETS 1
begin
  declare apiResult clob(50000) ccsid 1208;

  DECLARE ResultSet CURSOR FOR
    select * from JSON_TABLE(QSYS2.HTTP_GET(
      'https://us-south.ml.cloud.ibm.com/ml/v1/foundation_model_specs?version=2023-07-07'
    ), '$.resources[*]'
        COLUMNS(
          model_id VARCHAR(128) PATH '$.model_id',
          label VARCHAR(128) PATH '$.label',
          provider VARCHAR(128) PATH '$.provider',
          short_description VARCHAR(512) PATH '$.short_description'
        )
      ) x;

  OPEN ResultSet;
  SET RESULT SETS CURSOR ResultSet;
end;