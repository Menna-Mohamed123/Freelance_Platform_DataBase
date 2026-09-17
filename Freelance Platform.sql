create database Freelance_Platform
go
create table Users(
UserId int primary key IDENTITY(1,1) ,
Name varchar(100) not null,
Email varchar(100) unique  not null,
PasswordHash varchar(255) not null,
UserRole varchar(20) not null check(UserRole IN ('Client', 'Freelancer')), 
Country varchar(50)
)
go
create table Skills(
SkillId int primary key IDENTITY(1,1) ,
SkillName varchar(50) unique
)
go
create table UserSkills(
UserId int ,
SkillId int , 
primary key (UserId , SkillId) ,
foreign key(UserId) references Users(UserId) , 
foreign key (SkillId) references Skills(SkillId)
);
go
create table Projects (
ProjectId int primary key identity(1,1) ,
ClientId int references Users(UserId) ,
CategorySkillId int references Skills(SkillId) ,
Title varchar(200) not null ,
Budget Decimal (10,2) not null,
Proj_Status varchar(20) default 'Open' check(Proj_Status IN ('Open',
'In Progress', 'Completed', 'Cancelled')) 
)
go
create table Proposals(
ProposalId int primary key identity(1,1) ,
ProjectId int not null references Projects(ProjectId) ,
FreelancerId int not null references Users(UserId) ,
ProposedAmount decimal(10,2) not null check (ProposedAmount > 0),
DeliveryDays int not null check(DeliveryDays > 0)
constraint UQ_freelancer_project unique (ProjectId , FreelancerId)
)
go
create table Contracts(
ContractId int primary key identity(1,1) ,
ProposalId int  unique not null references Proposals(ProposalId) ,
FinalAmount decimal (10,2) not null check(FinalAmount > 0 ),
StartDate date not null ,
EndDate date ,
constraint check_dates check(EndDate >= Startdate)
)
go
create table Reviews(
ReviewId int primary key identity(1,1) ,
ContractId int  not null references Contracts(ContractId) ,
ReviewerId int not null references Users(UserId) ,
Rating tinyint not null check(Rating between 1 and 5) ,
ReviewComment varchar(1000) ,
constraint UQ_Constract_Review unique (ContractId , ReviewerId)
)
go
INSERT INTO Users (Name, Email, PasswordHash, UserRole, Country)
VALUES 
('Ahmed Khaled', 'ahmed@email.com', 'hashed_pass_123', 'Freelancer', 'Egypt'),
('Time Limit Solutions', 'contact@timelimit.com', 'hashed_pass_456', 'Client', 'Egypt'),
('Sara Youssef', 'sara@email.com', 'hashed_pass_789', 'Freelancer', 'Saudi Arabia'),
('Global Tech', 'info@globaltech.com', 'hashed_pass_000', 'Client', 'UAE');
GO
INSERT INTO Skills (SkillName)
VALUES 
('C#'), 
('ASP.NET Core'), 
('SQL Server'), 
('C++'), 
('Video Editing');
GO
INSERT INTO UserSkills (UserId, SkillId)
VALUES 
(1, 1), 
(1, 2), 
(1, 3),
(3, 4), 
(3, 5);
GO
INSERT INTO Projects (ClientId, CategorySkillId, Title, Budget, Proj_Status)
VALUES 
(2, 2, 'Build E-commerce Backend API using ASP.NET Core', 1500.00, 'Open'),
(4, 5, 'Edit a 10-minute YouTube Video', 300.00, 'Open');
GO
INSERT INTO Proposals (ProjectId, FreelancerId, ProposedAmount, DeliveryDays)
VALUES 
(1, 1, 1400.00, 15);
INSERT INTO Proposals (ProjectId, FreelancerId, ProposedAmount, DeliveryDays)
VALUES 
(2, 3, 250.00, 5);
GO

INSERT INTO Contracts (ProposalId, FinalAmount, StartDate, EndDate)
VALUES 
(1, 1400.00, '2026-09-01', '2026-09-16'),
(2, 250.00, '2026-09-01', '2026-09-06');
GO
INSERT INTO Reviews (ContractId, ReviewerId, Rating, ReviewComment)
VALUES 
(1, 2, 5, 'Highly professional Backend work, delivered ahead of schedule.'),
(2, 4, 4, 'Excellent video editing work and great effort.');
GO

select p.Title , p.ProjectId 
from Projects p join Users  u
on u.UserId = p.ClientId
where p.Proj_Status = 'Open' and u.Name ='Global Tech'

select p.Title as ProjectTitle, u.Name as FreelancerName, pr.ProposedAmount, pr.DeliveryDays
from Proposals pr
join Projects p ON pr.ProjectId = p.ProjectId
join Users u ON pr.FreelancerId = u.UserId;
GO
select c.ContractId, c.FinalAmount, r.Rating, r.ReviewComment
from Contracts c
left join Reviews r 
ON c.ContractId = r.ContractId;
GO
 
select 
    p.Title as ProjectTitle,
    client.Name as ClientName,
    freelancer.Name as FreelancerName,
    c.FinalAmount,
    c.StartDate,
    c.EndDate
FROM Contracts c
join Proposals pr ON c.ProposalId = pr.ProposalId
join Projects p ON pr.ProjectId = p.ProjectId
join Users client ON p.ClientId = client.UserId
join Users freelancer ON pr.FreelancerId = freelancer.UserId;
GO
-----------------------------------
create trigger UpdateStatus
on Contracts 
after insert
as 
update Projects
    set Proj_Status = 'In Progress'
    where ProjectId in (select ProjectId from Proposals join inserted 
    on Proposals.ProposalId = inserted.ProposalId )
    go

INSERT INTO Contracts (ProposalId, FinalAmount, StartDate, EndDate)
VALUES (3, 900.00, '2026-09-01', '2026-09-10');
GO

SELECT ProjectId, Title, Proj_Status AS 'Status After Contract' 
FROM Projects 
WHERE ProjectId = 3;
GO
-----------------------------------------
go
create proc FindProject @SkillName varchar(50)
as
select  p.title ,p.Budget 
from Projects p inner join Skills s
on s.SkillId = p.CategorySkillId
where s.SkillName = @SkillName and Proj_Status = 'Open'

go
EXEC FindProject @SkillName = 'ASP.NET Core';
-------------------------------------------
go
create function CalculatePlatformFee(@ProjectID int)
returns decimal(10,2)
as    begin
declare @fee decimal(10,2)
  select @fee = Budget
  from Projects
  where ProjectId = @ProjectID
  set @fee *= 0.1
  return @fee
       end
go
select dbo.CalculatePlatformFee(1) AS PlatformFee_Project1;

select  ProjectId, Title, Budget, dbo.CalculatePlatformFee(ProjectId) AS Platform_Commission 
FROM Projects;
--------------------------------------------------------
go 
 create view v_ContractsDashboard 
as 
select p.Title AS ProjectTitle,  client.Name AS ClientName,
freelancer.Name AS FreelancerName, c.FinalAmount, c.StartDate
FROM Contracts c
join Proposals pr on c.ProposalId = pr.ProposalId
join Projects p on pr.ProjectId = p.ProjectId
join Users client on p.ClientId = client.UserId
join Users freelancer on pr.FreelancerId = freelancer.UserId;
GO

 SELECT * FROM v_ContractsDashboard
 ------------------------------------------------------------
create nonclustered index IX_SkillName 
ON Skills(SkillName);
GO
------------------------------------------------------------
CREATE PROCEDURE CancelContract 
    @ContractID int
as
begin
    begin tran 
 
    begin try
        declare @ProjectID int;
        
        select @ProjectID = pr.ProjectId
        from Contracts c
        join Proposals pr ON c.ProposalId = pr.ProposalId
        where c.ContractId = @ContractID;

        delete from Contracts where ContractId = @ContractID;
        
        IF @ProjectID IS NOT NULL
        begin
            UPDATE Projects SET Proj_Status = 'Open' WHERE ProjectId = @ProjectID;
        END
        
        COMMIT TRAN; 
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN; 
        THROW;
    END CATCH
END;
GO 
