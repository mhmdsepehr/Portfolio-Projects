SELECT * FROM "CovidDeaths"
-- WHERE continent is not null
ORDER BY 3,4;
-- SELECT * FROM "CovidVaccinations" ORDER BY 3,4;

-- Select the data that we are going to be using.

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM "CovidDeaths"
ORDER BY 1,2;

-- Looking at total cases vs total deaths
-- Rough estimate of likelihood of dying if you contract covid in 'Canada'
SELECT Location, date, total_cases, total_deaths,
       (CAST(total_deaths as FLOAT)/CAST(total_cases as FLOAT))*100 as DeathPercentage
FROM "CovidDeaths"
WHERE location like 'Canada'
ORDER BY 1,2;

-- Looking at total cases vs population
-- Shows what percentage of population got covid.
SELECT Location, date, total_cases, population,
       (CAST(total_cases as FLOAT)/CAST(population as FLOAT))*100 as PercentPopulationInfected
FROM "CovidDeaths"
WHERE location like 'Canada'
ORDER BY 1,2;

-- Looking at countries with highest infection rate compared to population

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount,
       MAX(CAST(total_cases as FLOAT)/CAST(population as FLOAT))*100 as PercentPopulationInfected
FROM "CovidDeaths"
-- WHERE location like 'Canada'
group by Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Showing countries with the highest death count per population

SELECT Location, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM "CovidDeaths"
-- WHERE location like 'Canada'
WHERE continent is not null
group by Location
ORDER BY TotalDeathCount DESC;


-- Let's break things down by CONTINENT

-- Showing the continents with highest death count per population
SELECT continent, MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM "CovidDeaths"
-- WHERE location like 'Canada'
WHERE continent is not null
group by continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
       SUM(CAST(new_deaths as FLOAT))/SUM(CAST(new_cases as FLOAT))*100 as DeathPercentage
FROM "CovidDeaths"
WHERE continent is not null
GROUP BY date
ORDER BY 1,2;

-- IF WE WANT TO JUST LOOK AT THE TOTAL NUMBER ACROSS THE WORLD THEN
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
       SUM(CAST(new_deaths as FLOAT))/SUM(CAST(new_cases as FLOAT))*100 as DeathPercentage
FROM "CovidDeaths"
WHERE continent is not null
ORDER BY 1,2;


-- Looking at total population vs vaccination
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
       SUM(CAST(CV.new_vaccinations as int)) OVER (partition by CD.location ORDER BY CD.location, CD.date) as RollingTotalVaccinated
FROM "CovidDeaths" CD
JOIN "CovidVaccinations" CV ON
    CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent is not null
ORDER BY 2,3;


-- USE CTE
With PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingTotalVaccinated)
    as
         (
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
       SUM(CAST(CV.new_vaccinations as int)) OVER (partition by CD.location ORDER BY CD.location, CD.date) as RollingTotalVaccinated
FROM "CovidDeaths" CD
JOIN "CovidVaccinations" CV ON
    CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent is not null
)
SELECT *, (CAST(RollingTotalVaccinated as FLOAT)/CAST(Population AS FLOAT))*100 as PercentVaccinated
FROM PopVsVac
-----------------

-- TEMP TABLE
DROP TABLE IF EXISTS PercentPopulationVaccinated;
Create Table PercentPopulationVaccinated
(Continent varchar(255),
Location varchar(255),
Date DATE,
Population NUMERIC,
New_Vaccinations NUMERIC,
RollingTotalVaccinated NUMERIC
);

Insert into PercentPopulationVaccinated
SELECT CD.continent, CD.location, CAST(CD.date as DATE) , CD.population, CAST(CV.new_vaccinations as NUMERIC),
       SUM(CAST(CV.new_vaccinations as int)) OVER (partition by CD.location ORDER BY CD.location, CD.date) as RollingTotalVaccinated
FROM "CovidDeaths" CD
JOIN "CovidVaccinations" CV ON
    CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent is not null;

SELECT *, (CAST(RollingTotalVaccinated as FLOAT)/CAST(Population AS FLOAT))*100 as PercentVaccinated
FROM PercentPopulationVaccinated;



--  Let's create a VIEW to store data for later visualizations 

CREATE VIEW PercentPopVaccinated as
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
       SUM(CAST(CV.new_vaccinations as int)) OVER (partition by CD.location ORDER BY CD.location, CD.date) as RollingTotalVaccinated
FROM "CovidDeaths" CD
JOIN "CovidVaccinations" CV ON
    CD.location = CV.location AND CD.date = CV.date
WHERE CD.continent is not null;


SELECT * FROM PercentPopVaccinated;

