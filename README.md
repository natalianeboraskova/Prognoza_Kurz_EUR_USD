# Prognoza Kurz EUR/USD
V tomto projekte zameranom na analýzu a prognózovanie výmenného kurzu menového páru EUR/USD. Celá dátová analýza, štatistické testovanie a tvorba predikčných modelov prebehli v prostredí RStudio, pričom finálne vizualizácie a prehľady sú spracované pomocou Excelu. Cieľom projektu je preskúmať historické dáta, otestovať rôzne hypotézy a vytvoriť funkčné prognózy tohto kľúčového devízového trhu.

### Zdroje dát:
ECB - údaje pre EU

Fred - údaje pre USA


## Priebeh:

V počiatočnej fáze prebehla kontrola a transformácia dát. Identifikovaná metodická nekonzistencia v údajoch o inflácii bola odstránená prepočtom reálnych medziročných hodnôt pre USA, čím sa zabezpečila metodická kompatibilita s makroekonomickými premennými eurozóny. Následne bol dataset transformovaný na štruktúrovaný časový rad.
Modelovanie prebiehalo iteratívne prostredie klasických lineárnych regresií (lm) a pokročilých dynamických modelov (dynlm). Počas experimentálnej fázy sa testovali rôzne špecifikácie modelu – od rovníc zahŕňajúcich čisté makroekonomické ukazovatele až po modely so špecifickými úrokovými a inflačnými spreadmi.

<img width="949" height="705" alt="image" src="https://github.com/user-attachments/assets/38b1d19c-338d-4bc8-9588-0bea02e3f55b" />

Vstupná aplikácia oneskorenej premennej kurzu o jedno obdobie sa ukázala ako nežiaduca pre nadmernú dominanciu (prebratie väčšinovej vysvetľujúcej sily). Postupným zavádzaním optimálnych časových oneskoreni (lagov) – najmä pri inflácii a samotnom kurze o 4 obdobia dozadu – sa dynamika modelu stabilizovala.
Výsledným a najúspešnějším výstupom sa stal model34 (dynamický model s optimálnou štruktúrou oneskorení), ktorý najpresnejšie zachytáva komplexné vzťahy a dynamický vývoj na devízovom trhu EUR/USD.

<img width="663" height="498" alt="image" src="https://github.com/user-attachments/assets/4210838d-7eb9-4b6c-80c5-00b506ed8ba5" />


### Štatistická analýza finálneho modelu (`model34`)

* Model vykazuje vynikajúcu schopnosť vysvetliť variabilitu výmenného kurzu, pričom **Adjusted R-squared dosahuje hodnotu 0.8606** (t.j. model dokáže vysvetliť približne **86 % variability** kurzu EUR/USD).

* Takmer všetky kľúčové premenné (vrátane oneskoreného kurzu o 4 obdobia, inflácie EÚ aj USA, nezamestnanosti, úrokových sadzieb a 10-ročných dlhopisov USA) vykazujú vysokú štatistickú významnosť (hviezdičkové hodnotenie `***` alebo `**`), čo potvrdzuje ich opodstatnenie v modeli.

*Analýza pokrýva dáta časového radu od **mája 2001 do júna 2026**, pričom celkový model prešiel 292 stupňami voľnosti (Degrees of Freedom) s mimoriadne nízkou reziduálnou chybou (`Residual standard error: 0.05349`).



### Analýza stacionarity časových radov

V ekonometrii je stacionarita kľúčový krok, pretože práca s nestacionárnymi dátami môže viesť k zavádzajúcim (tzv. spurióznym) regresným výsledkom. Teda, pred samotným modelovaním prebehla dôkladná analýza vlastností časových radov s cieľom odhaliť prítomnosť trendov a jednotkových koreňov:

* Pomocou grafických nástrojov (`ggtsdisplay`, `acf2`) a štatistických testov sa potvrdilo, že pôvodný kurz EUR/USD je nestacionárny proces s výraznou autokoreláciou.
* Pre každú premennú datasetu (kurz, inflácia, nezamestnanosť, úrokové sadzby či dlhopisové výnosy) sa testovala prítomnosť jednotkového koreňa za pomoci rôznych špecifikácií (trend, drift, žiadny trend).
* Kým niektoré premenné vykazovali stacionaritu v úrovniach (resp. okolo deterministického trendu), samotný kurz EUR/USD a viaceré makroekonomické ukazovatele sa ukázali ako nestacionárne v úrovniach, pričom **stacionaritu nadobudli až v prvej diferencii** (čo znamená, že sú integrované prvého rádu $I(1)$)..

<img width="691" height="531" alt="image" src="https://github.com/user-attachments/assets/321bcf9b-81bd-40ed-83cd-36b5e502121e" />
<img width="691" height="531" alt="image" src="https://github.com/user-attachments/assets/233d9f72-d48b-4df2-bb44-55c52f75fec6" />


### Testovanie multikolinearity

* Na overenie toho, či sa vysvetľujúce premenné vo finálnom modeli (`model34`) navzájom nadmerne netopia alebo nekorelujú, bola aplikovaná funkcia `vif()`.
* Všetky vypočítané hodnoty VIF sa nachádzali pod štandardnou kritickou hranicou 10, čo znamená, že v modeli **nebola identifikovaná problematická multikolinearita** a odhady regresných koeficientov sú stabilné a štatisticky spoľahlivé.


### Analýza kointegrácie a dlhodobého vzťahu

* **Engle-Grangerov test kointegrácie -** Prostredníctvom ADF testu aplikovaného na reziduá pomocného regresného modelu sa overovalo, či medzi nestacionárnymi premennými existuje stabilný dlhodobý vzťah. Výsledky potvrdili stacionaritu reziduí, čo znamená, že **kointegrácia medzi premennými existuje** a model tak netrpí problémom spurióznej regresie.
* **Johansenov test (Trace test) -** Na hlbšie overenie kointegračných väzieb medzi vícerozmernými časovými radmi bol použitý Johansenov test s konštantou (`ecdet = "const"`) a lagom `K = 5`. Výstup trace testu preukázal prítomnosť až **3 kointegračných vzťahov**, čo potvrdzuje, že vybrané makroekonomické premenné a kurz EUR/USD sú dlhodobo proviazané a zdieľajú spoločnú stochastickú trendovú zložku.




## Overenie robustnosti a ochrana pred spurióznou regresiou

Keď finálny model dosiahol vysokú úspech (Adjusted $R^2 \approx 86$ %), bolo nutné podrobiť ho prísnemu overeniu, či nejde o tzv. **klamlivú (spurióznu) regresiu**.

V ekonometrii totiž práca s nestacionárnymi časovými radmi (kurz, inflácia, dlhopisy) môže viesť k iluzórnym výsledkom, kde model vykazuje skvelé štatistiky, hoci premenné spolu reálne nesúvisia a vezú sa len na spoločnom trende. Na vylúčenie tohto rizika prebehli nasledujúce kroky:

* **1. Testy stacionarity (ADF testy):** Overenie, že premenné dosahujú stacionaritu až v prvej diferencii ($I(1)$).
* **2. Kointegračná analýza:** Použitie Engle-Grangerovho a Johansenovho testu na preukázanie, že medzi nestacionárnymi premennými existuje reálna dlhodobá ekonomická rovnováha (Johansenov test potvrdil prítomnosť **3 kointegračných vzťahov**).

**Záver overenia:** Týmito testami sa odborne obhájilo, že vysoká presnosť modelu nie je náhodná zhoda, ale odraz skutočných a stabilných ekonomických väzieb medzi zvolenými makroekonomickými premennými a kurzom EUR/USD.


### Prognózovanie vývoja EUR/USD

Na základe získaných odhadnutých parametrov z finálneho dynamického modelu (`model34`) bola vytvorená prognostická skriptová časť. Dosadením očakávaných hodnôt vysvetľujúcich premenných (vrátane oneskoreného kurzu, inflácie, nezamestnanosti a výnosov dlhopisov) pre horizont **august až november 2026** model vygeneroval konkrétne bodové prognózy kurzu EUR/USD.

VVýsledky poskytujú prehľadný mesačný výhľad budúceho vývoja menového kurzu na základe kvantifikovaných ekonomických väzieb.

<img width="900" height="512" alt="image" src="https://github.com/user-attachments/assets/7b89edea-2e33-4a10-8ab4-7b8059b2d47e" />






