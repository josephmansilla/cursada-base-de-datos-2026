--1
CREATE TABLE auditoria(
nro_audit INT IDENTITY (1,1) PRIMARY KEY,
nom_tabla VARCHAR(30) NOT NULL,
operacion CHAR(1) CHECK (operacion IN ('I','O','N','D')),
row_data VARCHAR(255) NOT NULL,
usuario VARCHAR(30) DEFAULT suser_sname(),
fecha DATETIME DEFAULT getDate());GO

--2
CREATE PROCEDURE altaAuditoria (@nom_tabla VARCHAR(30), @operacion CHAR(1) , @row_data VARCHAR(255))
AS
BEGIN
INSERT INTO auditoria(nom_tabla, operacion,row_data)
VALUES (@nom_tabla,@operacion,@row_data)
END
GO

--3

CREATE TRIGGER ins_manufact ON manufact
AFTER INSERT
AS
DECLARE
@manu_code CHAR(3),
@manu_name VARCHAR(15),
@lead_time SMALLINT,
@state CHAR(2),
@string VARCHAR(255)

BEGIN
	DECLARE curInsertados CURSOR FOR 
              SELECT manu_code, manu_name, lead_time, state from inserted
	OPEN curInsertados
	FETCH NEXT FROM curInsertados into @manu_code, @manu_name, @lead_time, @state
	WHILE @@fetch_status=0
	BEGIN
		SET @string= @manu_code + ' | '+ @manu_name + ' | '+ cast (@lead_time as nvarchar)+' | '+ @state 
		EXEC altaAuditoria 'manufact', 'I', @string
		FETCH NEXT FROM curInsertados INTO @manu_code, @manu_name, @lead_time, @state
	END
CLOSE curInsertados
DEALLOCATE curInsertados
END
GO

drop trigger ins_manufact;
GO

--4
create trigger del_manufact on manufact
after delete
as
declare
@row_data varchar(255),
@manu_code char(3),
@manu_name varchar(15),
@lead_time smallint,
@state char(2)
begin
declare curBorrados cursor for select manu_code, manu_name, lead_time, state from deleted
open curBorrados

fetch next from curBorrados into @manu_code, @manu_name, @lead_time,@state
while @@fetch_status=0
	begin
	declare @string varchar(255)
	set @string= @manu_code + ' | '+ @manu_name + ' | '+ cast (@lead_time as nvarchar)+ ' | '+@state
	exec altaAuditoria 'manufact', 'D', @string
	fetch next from curBorrados into @manu_code, @manu_name, @lead_time,@state
	end
close curBorrados
deallocate curBorrados
end
GO

--5

create trigger upd_manufact on manufact
after update
as
declare
@row_dataB varchar(255),
@row_dataI varchar(255),
@manu_codeB char(3),
@manu_nameB varchar(15),
@lead_timeB smallint,
@manu_codeI char(3),
@manu_nameI varchar(15),
@lead_timeI smallint,
@stateB char(2),
@stateI char(2)
begin
declare curBorrados cursor for select manu_code, manu_name, lead_time, state from deleted

declare curInsertados cursor for select manu_code, manu_name, lead_time, state from inserted

open curBorrados
open curInsertados
fetch next from curBorrados into @manu_codeB, @manu_nameB, @lead_timeB, @stateB
fetch next from curInsertados into @manu_codeI, @manu_nameI, @lead_timeI, @stateI
	while @@fetch_status=0
	begin
	set @row_dataB= @manu_codeB + ' | '+ @manu_nameB + ' | '+ cast (@lead_timeB as nvarchar)+ ' | '+@stateB
	exec altaAuditoria 'manufact', 'O', @row_dataB
	set @row_dataI= @manu_codeI + ' | '+ @manu_nameI + ' | '+ cast (@lead_timeI as nvarchar)+ ' | '+@stateI
	exec altaAuditoria 'manufact', 'N', @row_dataI
	fetch next from curBorrados into @manu_codeB, @manu_nameB, @lead_timeB,@stateB
	fetch next from curInsertados into @manu_codeI, @manu_nameI, @lead_timeI,@stateI
	end
close curBorrados
deallocate curBorrados
close curInsertados
deallocate curInsertados
end
GO


--6
insert into manufact values ('XXX', 'Xtra large', 23)

update manufact 
set manu_name = 'Extra Large'
where manu_code='XXX' 

insert into manufact values ('XCX', 'Xtra large', 23)
delete from manufact where manu_code ='XCX'

select * from auditoria

--7
create table error_audit(
iderror  int identity(1,1) primary key,
error_number int,
error_line int,
error_status int,
error_message char(1000),
nom_tabla varchar(255) not null,
operacion char(1),
row_data varchar(255),
usuario varchar(30) default suser_sname(),
fecha datetime default getDate(),
estado char check(estado in('P','F')) default 'P');GO

drop table error_audit;GO

--8 Setear variables del motor


drop procedure altaAuditoria; GO


ALTER procedure altaAuditoria (@nom_tabla varchar(30), @operacion char(1) , @row_data varchar(255))
as
begin 
    DECLARE @xact_abort BIT = 'FALSE', 
        @options    INTEGER;

    SELECT @options = @@OPTIONS;
	 IF ( (16384 & @options) = 16384 ) 
	      begin 
		      PRINT 'XACT_ABORT vino en ON';
		      Set @xact_abort = 'TRUE';
          end 

    SET XACT_ABORT OFF;
	begin try
	SAVE TRANSACTION puntoDeSave;

	insert into auditoria(nom_tabla, operacion,row_data)
	values (@nom_tabla,@operacion,@row_data)
	--SELECT 1/0
        --PARA CAUSAR EL ERROR
	end try
	
	begin catch
	ROLLBACK TRANSACTION puntoDeSave;
	

	insert into error_audit (err_number,err_line,err_status,err_message,nom_tabla,operacion,row_data) 
	values(error_number(),  error_line(), error_state(),error_message(),@nom_tabla,@operacion, @row_data)
	
	end catch

    If @xact_abort = 'TRUE'
	    begin
		print ('Seteo XACT_abort en TruE');
	    SET XACT_ABORT ON
		end
end;
GO
-- 9. Procedure Reprocesa

CREATE PROCEDURE reprocesa_data
AS

BEGIN
	DECLARE CurReProcesa CURSOR FOR
	SELECT * FROM error_audit WHERE estado = 'P'

	DECLARE @iderror int, @err_number int,@err_line int, @err_status int, @err_message varchar(1000), 
        @nom_tabla varchar(30), @operacion char(1), @row_data varchar(255),@usuario varchar(30),@fecha datetime,@estado CHAR


	OPEN CurReProcesa;

	FETCH NEXT FROM CurReProcesa
	INTO @iderror,@err_number,@err_line, @err_status, @err_message,@nom_tabla, @operacion, @row_data,@usuario,@fecha,@estado

	WHILE @@FETCH_STATUS=0
	BEGIN
		BEGIN TRY
                        BEGIN TRAN
        		    UPDATE error_audit set estado = 'F' WHERE iderror=@iderror
	
   		            INSERT INTO auditoria (nom_tabla, operacion, row_data,usuario,fecha) 
                                  values (@nom_tabla, @operacion, @row_data,@usuario,@fecha)
			COMMIT TRAN
		END TRY

		BEGIN CATCH
			ROLLBACK TRAN
		END CATCH
	
        	FETCH NEXT FROM CurReProcesa
		INTO @iderror,@err_number,@err_line, @err_status, @err_message,@nom_tabla, @operacion, @row_data,@usuario,@fecha,@estado

	END

	CLOSE CurReProcesa
	DEALLOCATE CurReProcesa
END;
GO
	
