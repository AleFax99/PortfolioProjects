-- DATA EXPLORATION

-- Retreives all data contained in the table CovidDeaths
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4;

-- Retrieves all data contained in the table CovidVaccinations
SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4;

-- #########################################################################

-- Calculating the Death over Cases rate for Home Country
-- Shows likelihood of dying if you contract Covid in your country over the time.
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%Italy%'
ORDER BY 1,2;

-- Calculating the Total Cases over Population rate for Home Country 
-- Shows the percentage of population that contracts the virus over the time.
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS CasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%Italy%'
ORDER BY 1,2;

--############################################################################

-- Showing the countries with the Highest Infection Rate compared to Population
SELECT Location, 
	   population, 
	   MAX(total_cases) AS HighestInfectionCount, 
	   MAX(total_cases/population)*100 AS InfectedPercentage
FROM PortfolioProject..CovidDeaths
GROUP BY Location, population
ORDER BY InfectedPercentage DESC;

--##########################################################################

-- Showing the countries with the Highest Death Count

SELECT Location, 
       MAX(cast (Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location
ORDER BY TotalDeathCount DESC;

--###############################################################

-- Showing the continents with the Highest Death Count

SELECT continent, 
       MAX(cast (Total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- ###############################################################

-- Calculating the new Death rate according to new deaths and new cases data
-- Results are reoported over time.
SELECT date,
       SUM(new_cases) as totatal_new_cases, 
	   SUM(CAST (new_deaths AS INT)) AS total_new_deaths, 
	   SUM(CAST (new_deaths AS INT))/SUM(New_cases)*100 AS NewDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2;


--#####################################################

-- Calculating the Vaccinations over Population rate per Country
-- How many people are vaccinated as of the last day recorded?
-- Running total of vaccinated per country over time
SELECT dea.continent, 
       dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations, 
	   SUM(CAST (new_vaccinations AS INT)) 
	   OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated--,
	   --(Rolling_People_Vaccinated/Population)*100 AS Percent_Vaccination*
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
     ON dea.location = vac.location 
	 AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;

-- *Problem: it is not possible to reference a calculated column within a different element of the select list. 
-- Here, it is only possible to visualize the running total of vaccinations (per country). 
-- To also add the column Percent_Vaccination, one must either use CTE or Temporary tables:

-- 1st method:
-- USE CTE
WITH PopvsVac (Continent, 
               Location, 
			   Date, 
			   Population, 
			   New_Vaccinations, 
			   Rolling_People_Vaccinated)
AS 
(
SELECT dea.continent, 
       dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations, 
	   SUM(CAST (new_vaccinations AS INT)) 
	   OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
     ON dea.location = vac.location 
	 AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (Rolling_People_Vaccinated/Population)*100 AS Percent_Vaccination
FROM PopvsVac

-- 2nd method: 
-- TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
             (
			 Continent nvarchar(255),
			 Location nvarchar(255),
			 Date datetime,
			 Population numeric, 
			 New_vaccinations numeric, 
			 Rolling_People_Vaccinated numeric
			 )

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, 
       dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations, 
	   SUM(CAST (new_vaccinations AS INT)) 
	   OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
     ON dea.location = vac.location 
	 AND dea.date = vac.date
--WHERE dea.continent is not null

SELECT *, (Rolling_People_Vaccinated/Population)*100 AS Percent_Vaccination
FROM #PercentPopulationVaccinated;


-- ############################################################

-- Creating a view to store data for later visualizations

CREATE VIEW Vaccinations AS
SELECT dea.continent, 
       dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations, 
	   SUM(CAST (new_vaccinations AS INT)) 
	   OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
     ON dea.location = vac.location 
	 AND dea.date = vac.date
WHERE dea.continent is not null

SELECT * 
FROM Vaccinations