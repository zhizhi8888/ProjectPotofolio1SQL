SELECT *
  FROM [PortfolioProject1].[dbo].[CovidVaccination];
SELECT *
  FROM [PortfolioProject1].[dbo].[CovidDeaths];

/*1. select the data that we are going to start with. */
Select Location, date, total_cases, new_cases, total_deaths, population
From [PortfolioProject1].[dbo].[CovidDeaths]
Where continent is not null ;

-- 2.Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country, eg: the situation of US

Select Location, date, total_cases,total_deaths, (cast(Total_deaths as int)/total_cases)*100 as DeathPercentage
From [PortfolioProject1].[dbo].[CovidDeaths]
Where location like '%states%'
and continent is not null
order by 1,2;

-- 3.Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From [PortfolioProject1].[dbo].[CovidDeaths]
Where continent is not null
-- and location like '%states%';
order by 1,2;

-- 4.Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [PortfolioProject1].[dbo].[CovidDeaths]
Group by Location, Population 
order by PercentPopulationInfected desc

--5. Countries with Highest Death Count per Population

Select Location, SUM(cast(new_deaths as int)) as TotalDeathCount
From [PortfolioProject1].[dbo].[CovidDeaths]
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- 6.Showing contintents with the highest death count per population

Select continent, SUM(cast(new_deaths as int)) as TotalDeathCount
From [PortfolioProject1].[dbo].[CovidDeaths]
Where continent is not null
Group by continent
order by TotalDeathCount desc


--7. GLOBAL NUMBERS about cases deaths and deathPercentage

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From [PortfolioProject1].[dbo].[CovidDeaths]
where continent is not null
Group by location
Order by TotalDeathCount DESC;


--8. GLOBAL NUMBERS 
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From [PortfolioProject1].[dbo].[CovidDeaths]
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

--9.Total Population vs Vaccinations
-- 9.1 Shows Percentage of Population that has recieved at least one Covid Vaccine

ALTER TABLE CovidDeaths 
ALTER COLUMN date  nvarchar(100)
Select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
From [PortfolioProject1].[dbo].[CovidDeaths] dea
Join [PortfolioProject1].[dbo].[CovidVaccination] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null;

--9.2 Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [PortfolioProject1].[dbo].[CovidDeaths] dea
Join [PortfolioProject1].[dbo].[CovidVaccination] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
	)
Select *, (RollingPeopleVaccinated/Population)*100 as CovidVaccineRate
From PopvsVac


--9.3 Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location,  dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [PortfolioProject1].[dbo].[CovidDeaths] dea
Join [PortfolioProject1].[dbo].[CovidVaccination] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
Select *, (RollingPeopleVaccinated/Population)*100 as CovidVaccineRate
From #PercentPopulationVaccinated
