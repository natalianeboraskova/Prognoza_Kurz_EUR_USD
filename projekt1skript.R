library(readxl)
newfileshow <- read_excel("kurzk.xlsx")
View(newfileshow) 


# + 

library(readxl)
library(seasonal)
library(astsa)
library(forecast)
library(urca)
library(tidyverse)
library(dynlm)
library(car)
library(ggplot2)
library(tidyr)
library(dplyr)
library(lmtest)
library(sandwich)


#prepočitanie tej inflacie aby boli data spravne
newfileshow$INFLACIA_US_YOY_REAL <- 100 * (newfileshow$INFLACIA_US_YOY /dplyr::lag(newfileshow$INFLACIA_US_YOY, 12)- 1)
head(newfileshow$INFLACIA_US_YOY_REAL, 20) 

#time series
caspas <- ts(newfileshow[, c("KURZ","INFLACIA_EU","INFLACIA_US_YOY_REAL","Unemployment_EU","Unemployment_US","ur.m.EU","ur.m.US","RateSpread","GER_10Y_Yield","US_10Y_Yield","YieldSpread")],start = c(2000, 1),frequency = 12)
View(caspas)

#MODELY:   --------------------------------------------------------------------------------------------------------x
model<-lm(KURZ ~ INFLACIA_EU +INFLACIA_US_YOY_REAL + Unemployment_EU + Unemployment_US + ur.m.EU +ur.m.US +RateSpread+ GER_10Y_Yield+US_10Y_Yield +YieldSpread, data = newfileshow)
summary(model)
#model bez spreadov ale s raw hodnotami
model1<-lm(KURZ ~ INFLACIA_EU+INFLACIA_US_YOY_REAL + Unemployment_EU + Unemployment_US + ur.m.EU +ur.m.US + GER_10Y_Yield+US_10Y_Yield, data = newfileshow)
summary(model1) 
#model s spreadmi ale bez raw hodnot
model2<-lm(KURZ ~ INFLACIA_EU+INFLACIA_US_YOY_REAL + Unemployment_EU + Unemployment_US + RateSpread+ YieldSpread, data = newfileshow)
summary(model2) 
model12<-dynlm(KURZ ~ L(INFLACIA_EU, 4)+L(INFLACIA_US_YOY_REAL, 4) + Unemployment_EU + Unemployment_US + ur.m.EU +ur.m.US + GER_10Y_Yield+US_10Y_Yield, data = newfileshow)
summary(model12)
model13<-dynlm(KURZ ~ INFLACIA_EU+INFLACIA_US_YOY_REAL + Unemployment_EU + Unemployment_US + ur.m.EU +ur.m.US + L(GER_10Y_Yield,4) +US_10Y_Yield, data = newfileshow)
summary(model13)
#Chcel som vysvetliť vývoj EUR/USD pomocou makroekonomických ukazovateľov. Začal som teoretickým výskumom determinantov kurzu, následne som zbieral historické dáta z ECB a FRED. Pri modelovaní som narazil na problémy s multikolinearitou a nekonzistentnou definíciou inflácie medzi USA a EÚ. Po úprave dát a testovaní viacerých špecifikácií model dosiahol Adjusted R² približne 0.32 a potvrdil významný vplyv inflácie, nezamestnanosti a úrokových sadzieb
#chyba v inflacií: Zistil som, že používam medziročnú infláciu eurozóny a medzimesačnú infláciu USA, čo skresľovalo výsledky. Až po zjednotení metodiky sa model výrazne zlepšil.
model31<-dynlm(KURZ ~ L(KURZ,1)+ INFLACIA_EU+INFLACIA_US_YOY_REAL + Unemployment_EU + Unemployment_US + ur.m.EU +ur.m.US +US_10Y_Yield, data = newfileshow)
summary(model31)
#pridanie medzi premenne oneskorený kurz o jedno obdobie sa ukazalo ako zle lebo to prebralo vycsinovu vysvtlujucu hodnotu

model3<-lm(KURZ ~ INFLACIA_EU+INFLACIA_US_YOY_REAL + Unemployment_EU + Unemployment_US + ur.m.EU +ur.m.US +US_10Y_Yield, data = newfileshow)
summary(model3)

#-----------------------------------------------------------X
newfileshow$InflationSpread <-newfileshow$INFLACIA_US_YOY_REAL -newfileshow$INFLACIA_EU
newfileshow$UnemploymentSpread <-newfileshow$Unemployment_US -newfileshow$Unemployment_EU
newfileshow$RateSpread <-newfileshow$ur.m.US -newfileshow$ur.m.EU
#-----------------------------------------------------------x

model_spread <- lm(KURZ ~ InflationSpread +UnemploymentSpread +RateSpread +US_10Y_Yield,data = newfileshow)
summary(model_spread) 

model32<-dynlm(KURZ ~ L(KURZ,4)+INFLACIA_EU+INFLACIA_US_YOY_REAL + Unemployment_EU + Unemployment_US + ur.m.EU +ur.m.US +US_10Y_Yield, data = caspas)
summary(model32) 
model33<-dynlm(KURZ ~ L(KURZ,4)+L(INFLACIA_EU,4)+L(INFLACIA_US_YOY_REAL,4) + Unemployment_EU + Unemployment_US + ur.m.EU +ur.m.US +US_10Y_Yield, data = caspas)
summary(model33) 


model34<-dynlm(KURZ ~ L(KURZ,4)+L(INFLACIA_EU,4)+L(INFLACIA_US_YOY_REAL,4) + Unemployment_EU + L(Unemployment_US,4) + ur.m.EU +ur.m.US +US_10Y_Yield, data = caspas)
summary(model34) 
#uplne najlepsi model         !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!                                           !!!!!!!!!!!!!

# PRIPRAVA DAT PRE GGPLOT (prevod z ts na dataframe)   ------------------------------------------------------------x
data_df <- data.frame(
  time = as.numeric(time(caspas)),
  KURZ = as.numeric(caspas[,"KURZ"]),
  KURZ_L4 = dplyr::lag(as.numeric(caspas[,"KURZ"]), 4),
  INFLACIA_EU_L4 =
    dplyr::lag(as.numeric(caspas[,"INFLACIA_EU"]), 4),
  INFLACIA_US_YOY_REAL_L4 =
    dplyr::lag(as.numeric(caspas[,"INFLACIA_US_YOY_REAL"]), 4),
  Unemployment_EU =
    as.numeric(caspas[,"Unemployment_EU"]),
  Unemployment_US_L4 =
    dplyr::lag(as.numeric(caspas[,"Unemployment_US"]), 4),
  ur.m.EU =
    as.numeric(caspas[,"ur.m.EU"]),
  ur.m.US =
    as.numeric(caspas[,"ur.m.US"]),
  US_10Y_Yield =
    as.numeric(caspas[,"US_10Y_Yield"]))

data_long <- data_df %>%
  pivot_longer(
    cols = c(
      KURZ,
      KURZ_L4,
      INFLACIA_EU_L4,
      INFLACIA_US_YOY_REAL_L4,
      Unemployment_EU,
      Unemployment_US_L4,
      ur.m.EU,
      ur.m.US,
      US_10Y_Yield
    ),
    names_to = "premenna",
    values_to = "hodnota"
  )

ggplot(data_long, aes(x = time, y = hodnota, color = premenna)) +
  geom_line(linewidth = 0.8) +
  facet_wrap(~ premenna, scales = "free_y", ncol = 1) +
  labs(title = "Vývoj premenných",
       x = "Rok", 
       y = "Index",
       caption = "Zdroj: Vlastné spracovanie na základe údajov z Eurostatu") +
  theme_minimal() +
  theme(legend.position = "none",
        strip.text = element_text(face = "bold"))


#ACF a PACF STACIONARITA: ---------------------------------------------------------------------------------x
#KURZ
acf2(caspas[,1],4) 
ggtsdisplay(caspas[,1])
qchisq(0.95,4)   #9.487729
Box.test(caspas[,1],lag=4,type="Lj",fitdf = 0)
#zaver-> proces je NESTACIONARNY, autokorelácia



#Kurz -                   prva diferencia stacionarna
#Inflacia_eu -            stacionarna trend
#inflacia_us -            diferencia je stacionarna
#unemployment_eu -        diferencia je stacionarna
#unemployment_us -        diferencia je stacionarna
#ur.m.EU -                diferencia je stacionarna
#ur.m.US -                stacionarna
#ger10YELD -              stacionarna



#Dickeyho-fullerov test KURZ
summary(ur.df(caspas[,1],type="trend",lags=10,selectlags="BIC"))                      
summary(ur.df(caspas[,1],type="trend",lags=1))                                      
#nie je vhodny
#model s konstantou-drift-konstanta, pre model s driftom 
summary(ur.df(caspas[,1],type="drift",lags=10,selectlags="BIC"))
summary(ur.df(caspas[,1],type="drift",lags=1))                                      
# nie je vhodny
#model bez trendu a konstanty
summary(ur.df(caspas[,1],type="none",lags=10,selectlags="BIC"))
summary(ur.df(caspas[,1],type="none",lags=1))      
#prijmam H0 a tvrdime, že hdp je random walk - nestacionarny 
#stacionarita diferencii
summary(ur.df(diff(caspas[,1]),type="trend",lags=10,selectlags="BIC"))
summary(ur.df(diff(caspas[,1]),type="trend",lags=1))
#model je vhodny a prva diferencia je stacionarna - Model je integrovaný prveho radu I(1)

#Dickeyho-fullerov test INFLACIA_EU
summary(ur.df(caspas[,2],type="trend",lags=10,selectlags="BIC"))                      
summary(ur.df(caspas[,2],type="trend",lags=7))                                      
#model je vhodny a je stacionarna

#Dickeyho-fullerov test INFLACIA_US_YOY
infl_us <- as.numeric(caspas[,3])
infl_us <- infl_us[!is.na(infl_us)]
summary(ur.df(infl_us,type="trend",lags=10,selectlags="BIC"))                      
summary(ur.df(infl_us,type="trend",lags=2))                                      
summary(ur.df(infl_us,type="drift",lags=10,selectlags="BIC"))                      
summary(ur.df(infl_us,type="drift",lags=2))
summary(ur.df(infl_us,type="none",lags=10,selectlags="BIC"))                      
summary(ur.df(infl_us,type="none",lags=2))
#Nestacionárny
#stacionarita diferencii
summary(ur.df(diff(infl_us),type="trend",lags=10,selectlags="BIC"))
summary(ur.df(diff(infl_us),type="trend",lags=1))
#diferencia je stacionarna

#Dickeyho-fullerov test unemployment_EU
unempEU <- as.numeric(caspas[,4])
unempEU <- unempEU[!is.na(unempEU)]
summary(ur.df(unempEU,type="trend",lags=10,selectlags="BIC"))                      
summary(ur.df(unempEU,type="trend",lags=2))                                      
summary(ur.df(unempEU,type="drift",lags=10,selectlags="BIC"))                      
summary(ur.df(unempEU,type="drift",lags=2))
summary(ur.df(unempEU,type="none",lags=10,selectlags="BIC"))                      
summary(ur.df(unempEU,type="none",lags=2))
summary(ur.df(diff(unempEU),type="trend",lags=10,selectlags="BIC"))
summary(ur.df(diff(unempEU),type="trend",lags=1))
#diferencia je stacionarna

#Dickeyho-fullerov test unemployment_US
unempUS <- as.numeric(caspas[,5])
unempUS <- unempUS[!is.na(unempUS)]
summary(ur.df(unempUS,type="trend",lags=10,selectlags="BIC"))                      
summary(ur.df(unempUS,type="trend",lags=1))                                      
summary(ur.df(unempUS,type="drift",lags=10,selectlags="BIC"))                      
summary(ur.df(unempUS,type="drift",lags=1))
summary(ur.df(unempUS,type="none",lags=10,selectlags="BIC"))                      
summary(ur.df(unempUS,type="none",lags=1))
summary(ur.df(diff(unempUS),type="trend",lags=10,selectlags="BIC"))
summary(ur.df(diff(unempUS),type="trend",lags=1))
#diferencia je stacionarna

#Dickeyho-fullerov test ur.m.eu
ur.m.eu <- as.numeric(caspas[,6])
ur.m.eu <- ur.m.eu[!is.na(ur.m.eu)]
summary(ur.df(ur.m.eu,type="trend",lags=10,selectlags="BIC"))                      
summary(ur.df(ur.m.eu,type="trend",lags=3))                                      
summary(ur.df(ur.m.eu,type="drift",lags=10,selectlags="BIC"))                      
summary(ur.df(ur.m.eu,type="drift",lags=3))
summary(ur.df(ur.m.eu,type="none",lags=10,selectlags="BIC"))                      
summary(ur.df(ur.m.eu,type="none",lags=1))
summary(ur.df(diff(ur.m.eu),type="trend",lags=10,selectlags="BIC"))
summary(ur.df(diff(ur.m.eu),type="trend",lags=2))
#diferencia je stacionarna

#Dickeyho-fullerov test ur.m.us
ur.m.us <- as.numeric(caspas[,7])
ur.m.us <- ur.m.us[!is.na(ur.m.us)]
summary(ur.df(ur.m.us,type="trend",lags=10,selectlags="BIC"))                      
summary(ur.df(ur.m.us,type="trend",lags=3))                                      
summary(ur.df(ur.m.us,type="drift",lags=10,selectlags="BIC"))                      
summary(ur.df(ur.m.us,type="drift",lags=5))
#premenna s driftom je stacionarna

#Dickeyho-fullerov test GER10YELD
GER10YELD <- as.numeric(caspas[,8])
GER10YELD <- GER10YELD[!is.na(GER10YELD)]
summary(ur.df(GER10YELD,type="trend",lags=10,selectlags="BIC"))                      
summary(ur.df(GER10YELD,type="trend",lags=3))                                      
summary(ur.df(GER10YELD,type="drift",lags=10,selectlags="BIC"))                      
summary(ur.df(GER10YELD,type="drift",lags=3))
#stacionarna


#MULTIKOLINEARITA ----------------------------------------------------------------------------x
#vsetko je vif<10 takže fajn - žiadna multikolinearita
vif(model34)







#KOINTEGRACIA----------------------------------------------------------------------------------x
(coint<-summary(lm(KURZ ~ KURZ+INFLACIA_EU+INFLACIA_US_YOY_REAL + Unemployment_EU + Unemployment_US + ur.m.EU +ur.m.US +US_10Y_Yield, data = caspas)))
summary(ur.df(resid(coint),type = "none", lags=10, selectlags ="BIC"))
summary(ur.df(resid(coint),type = "none", lags=1))
#existuje kointegracia

coint_data <- na.omit(newfileshow[, c(
  "KURZ",
  "INFLACIA_EU",
  "INFLACIA_US_YOY_REAL",
  "Unemployment_EU",
  "Unemployment_US",
  "ur.m.EU",
  "ur.m.US",
  "US_10Y_Yield"
)])

joh <- ca.jo(
  coint_data,
  type = "trace",
  ecdet = "const",
  K = 5
)
summary(joh)
#existuju 3 kointegračne vztahy


#Prognozovanie_ECM-------------------------------------------------------------------x
#dlhodoba rovnica
b<-coef(model34)

forecast34 <- c(
  b["(Intercept)"] +
    b["L(KURZ, 4)"] * 1.1558 +
    b["L(INFLACIA_EU, 4)"] * 2.6 +
    b["L(INFLACIA_US_YOY_REAL, 4)"] * 3.285958 +
    b["Unemployment_EU"] * 6.3 +
    b["L(Unemployment_US, 4)"] * 4.3 +
    b["ur.m.EU"] * 2.00 +
    b["ur.m.US"] * 3.64 +
    b["US_10Y_Yield"] * 0.53,
  b["(Intercept)"] +
    b["L(KURZ, 4)"] * 1.1706 +
    b["L(INFLACIA_EU, 4)"] * 3.0 +
    b["L(INFLACIA_US_YOY_REAL, 4)"] * 3.779246 +
    b["Unemployment_EU"] * 6.3 +
    b["L(Unemployment_US, 4)"] * 4.3 +
    b["ur.m.EU"] * 2.25 +
    b["ur.m.US"] * 3.63 +
    b["US_10Y_Yield"] * 0.36,
  b["(Intercept)"] +
    b["L(KURZ, 4)"] * 1.1673 +
    b["L(INFLACIA_EU, 4)"] * 3.2 +
    b["L(INFLACIA_US_YOY_REAL, 4)"] * 4.166615 +
    b["Unemployment_EU"] * 6.3 +
    b["L(Unemployment_US, 4)"] * 4.3 +
    b["ur.m.EU"] * 2.25 +
    b["ur.m.US"] * 3.63 +
    b["US_10Y_Yield"] * 0.36,
  b["(Intercept)"] +
    b["L(KURZ, 4)"] * 1.1518 +
    b["L(INFLACIA_EU, 4)"] * 2.8 +
    b["L(INFLACIA_US_YOY_REAL, 4)"] * 3.463531 +
    b["Unemployment_EU"] * 6.3 +
    b["L(Unemployment_US, 4)"] * 4.2 +
    b["ur.m.EU"] * 2.25 +
    b["ur.m.US"] * 3.63 +
    b["US_10Y_Yield"] * 0.36)

forecast34
data.frame(Mesiac = c("Aug 2026", "Sep 2026", "Oct 2026", "Nov 2026"),Prognóza_EURUSD = forecast34)

  



