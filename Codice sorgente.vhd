----------------------------------------------------------------------------------
-- Componenti gruppo:
-- 
-- ANDREA TRESOLDI
-- matricola: 847387
-- codice persona: 10535801
-- SIMONE ZANI
-- matricola: 846664
-- codice persona: 10502938
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR (7 downto 0);
           o_address : out STD_LOGIC_VECTOR (15 downto 0);
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR (7 downto 0));
end project_reti_logiche;

architecture myComponent of project_reti_logiche is

    type state_type is (reset, S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13);           --stati del nostro componente
    signal nextState : state_type := reset;                                                           --segnale per memorizzare lo stato della macchina; inizialmente siamo nello stato di reset
    signal mask_out : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');                               --segnale mask_out per salvare il risultato dell'elaborazione
    signal mask_in : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');                                --segnale mask_in per salvare la maschera letta dalla memoria
    signal updateMask : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');                             --segnale di supporto per aggiornare la maschera di uscita (viene utilizzata in maniera diversa a seconda che la distanzaManatthanAttuale sia maggiore minore o uguale a distanzaMinima ovvero la soglia all'i-esima iterazione
    signal xPoint : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');                                 --segnale per memorizzare il valore della coordinata X contenuto nell'indirizzo 17 della memoria
    signal yPoint : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');                                 --segnale per memorizzare il valore della coordinata Y contenuto nell'indirizzo 18 della memoria
    signal distanzaMinima : STD_LOGIC_VECTOR (8 downto 0) := (8 downto 1 => '1', others => '0');      --inizialmente la distanzaMinima vale 510 (valore massimo ottenibile utilizzando per il calcolo la distanza di Manhattan ); aggiorneremo il segnale se un nuovo centroide ha distanza minore rispetto a questa soglia
    signal distanzaManhattanAttuale : STD_LOGIC_VECTOR (8 downto 0) := (others => '0');               --segnale per memorizzare la distanza di Manhattan del punto dal cont-esimo centroide
    signal distanzaXcentroide : STD_LOGIC_VECTOR (8 downto 0) := (others => '0');                     --segnale per memorizzare la distanza della x del punto dalla x del cont-esimo centroide
    signal distanzaYcentroide : STD_LOGIC_VECTOR (8 downto 0) := (others => '0');                     --segnale per memorizzare la distanza della y del punto dalla y cont-esimo centroide
    signal xCentroide : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');                             --segnale per memorizzare il valore della coordinata X del centroide considerato per l'iesima computazione
    signal yCentroide : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');                             --segnale per memorizzare il valore della coordinata Y del centroide considerato per l'iesima computazione
    signal cont : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');                                  --segnale cont per iterare su tutti i bit della maschera
   
begin
    process(i_clk, i_rst)
    begin
        if i_rst='1' then                                                                             --fronte di salita del reset
            mask_out <= (others => '0');                                                              --riassegno a tutti i segnali del nostro circuito i valori di inizializzazione(dati al primo assegnamento all 'interno dell architecture), in modo che, se dovesse arrivare un segnale di reset, la macchina ? pronta ad iniziare una nuova computazione senza avere inconsistenza sui valori dei segnali
            mask_in <= (others => '0'); 
            updateMask <= (others => '0');
            xPoint <= (others => '0');
            yPoint <= (others => '0');
            distanzaMinima <= (8 downto 1 => '1', others => '0');
            distanzaManhattanAttuale <= (others => '0');
            distanzaXcentroide <= (others => '0');
            distanzaYcentroide <= (others => '0');
            xcentroide <= (others => '0');
            ycentroide <= (others => '0');
            cont <= (others => '0');
            o_address <= (others => '0');
            o_done <= '0';
            o_en <= '0';
            o_we <= '0';
            o_data <= (others => '0');			
		    nextState <= reset;
        elsif rising_edge(i_clk) then                                                                 --fronte di salita del clock
            case nextState is
                when reset =>
                    if i_start='1' then                                                               --se il segnale di start ? alto allora iniziamo l'elaborazione andando in S0  
                        nextState <= S0;
                    else 
                        nextState <= reset;
                    end if;
                when S0 =>
                    o_en <= '1';                                                                      --imposto o_en a 1 per poter accedere alla memoria
                    o_we <= '0';
                    o_address <= "0000000000010001";                                                  --imposto il segnale o_address a 17 per accedere alla coordinata X del punto
                    nextState <= S1;
                when S1 =>
                    o_address <= "0000000000010010";                                                  --imposto il segnale o_address a 18 per accedere alla coordinata Y del punto
                    nextState <= S2;
                when S2 =>
                    xPoint <= i_data;                                                                 --salvo nel segnale xPoint il valore corrispondete alla cella 17 (X del punto)
                    o_address <= "0000000000000000";                                                  --imposto il segnale o_address a 0 per accedere alla maschera d'ingresso in memoria
                    nextState <= S3;
                when S3 =>
                    yPoint <= i_data;                                                                 --salvo nel segnale yPoint il valore corrispondete alla cella 18 (Y del punto)
                    nextState <= S4; 
                when S4 => 
                     mask_in <= i_data;                                                               --salvo nel segnale mask_in la maschera in ingresso presente in memoria
                     nextState <= S5;                                                                 
                when S5 =>                                                                            --in questo stato abbiamo a disposizione la maschera in ingresso e le coordinate del punto nei corrispondenti segnali mask_in, xPoint, yPoint
                     if cont > "0000000000000111" then                                                --se cont > 7 significa che abbiamo letto tutti i bit di mask_in; quindi nel segnale mask_out ? memorizzata la maschera di uscita definitiva pronta per essere scritta in memoria
                        o_we <= '1';                                                                  --imposto o_we a 1 per poter scrivere in memoria
                        o_address <= "0000000000010011";                                              --imposto il segnale o_address a 19 per poter scrivere la maschera d'uscita nella cella con indirizzo 19
                        o_data <= mask_out;                                                           --assegno a o_data il valore di mask-out che contiene la maschera di uscita corretta
                        nextState <= S12;
                     elsif mask_in(CONV_INTEGER(cont)) = '0' then                                     --se il cont-esimo bit di mask_in ? pari a 0 non dobbiamo considerare il rispettivo centroide e quindi incrementiamo il contatore e rimaniamo in S5
                        cont <= STD_LOGIC_VECTOR(UNSIGNED(cont) + 1);                                 --incremento il contatore                               
                        nextState <= S5;                     
                     else
                        o_address <= STD_LOGIC_VECTOR(UNSIGNED(cont) + UNSIGNED(cont) + 1);           --se il cont-esimo bit di mask_in ? pari a 1 allora impostiamo o_address a (cont + cont) + 1 per poter accedere in memoria alla coordinata X del centroide
                        updateMask(CONV_INTEGER(cont)) <= '1';                                        --aggiorniamo il segnale updateMask in modo tale che all'iterazione cont-esima, il bit in posizione cont-esima valga 1 e gli altri bit valgano 0
						nextState <= S6;
                    end if;
                when S6 => 
                    o_address <= STD_LOGIC_VECTOR(UNSIGNED(cont) + UNSIGNED(cont) + 2);               --impostiamo o_address a (cont + cont) + 2 per poter accedere in memoria alla coordinata Y del centroide
                    nextState <= S7;
                when S7 =>
                    xCentroide <= i_data;                                                             --salvo nel segnale xCentroide il valore corrispondete alla cella con indirizzo (cont + cont) + 1 (X del centroide)
                    nextState <= S8; 
                when S8 => 
                    yCentroide <= i_data;                                                             --salvo nel segnale yCentroide il valore corrispondete alla cella con indirizzo (cont + cont) + 2 (Y del centroide) 
                    nextState <=S9;
                when S9 =>                                                                            --in questo stato abbiamo a disposizione in xCentroide e yCentroide le coordinate del centroide corrispondente al cont-esimo bit della maschera in ingresso
                   if xPoint >= xCentroide then                                                       --calcoliamo distanzaXcentroide e distanzaYcentroide facendo i vari controlli sul valore dei segnali per ottenere sempre un valore positivo come risultato della sottrazione( per evitare di utilizzare la funzione abs())
                       distanzaXcentroide <= STD_LOGIC_VECTOR(UNSIGNED('0' & xPoint(7 downto 0)) - UNSIGNED('0' & xCentroide(7 downto 0)));  --concateniamo un bit a xPoint e xCentroide perchè? questi due segnali sono di 8 bit mentre il segnale distanzaXcentroide ? di 9 bit
                   else 
                       distanzaXcentroide <= STD_LOGIC_VECTOR(UNSIGNED('0' & xCentroide(7 downto 0)) - UNSIGNED('0' & xPoint(7 downto 0)));
                   end if;
                    
                   if yPoint >= yCentroide then
                       distanzaYcentroide <= STD_LOGIC_VECTOR(UNSIGNED('0' & yPoint(7 downto 0)) - UNSIGNED('0' & yCentroide(7 downto 0)));  --concateniamo un bit a yPoint e yCentroide perchè? questi due segnali sono di 8 bit mentre il segnale distanzaYcentroide ? di 9 bit
                   else 
                      distanzaYcentroide <= STD_LOGIC_VECTOR(UNSIGNED('0' & yCentroide(7 downto 0)) - UNSIGNED('0' & yPoint(7 downto 0)));
                    end if; 
                    nextState <= S10;
               when S10 =>                                                                            --ora abbiamo a disposizione le distanze per calcolare la distanza di Manhattan
                    distanzaManhattanAttuale <= STD_LOGIC_VECTOR(UNSIGNED(distanzaXcentroide) + UNSIGNED(distanzaYcentroide)); --calcolo dustanza di Manhattan sommando le due distanze parziali calcolate nello stato precedente
                    nextState <= S11;
               when S11 =>
                    updateMask <= (others => '0');                                                    --assegnamo a tutti i bit del segnale 0 in modo da avere il segnale inizializzato ad ogni iterazione del processo
					if distanzaManhattanAttuale < distanzaMinima then                                 --se la distanza di Manhattan, calcolata durante l'iterazione attuale, è strettamente minore della soglia, ovvero della distanza minima corrente, entriamo in questo ramo if 
                        mask_out <= updateMask;                                                       --assegnamo al segnale mask_out il segnale updateMask in modo tale che il bit di mask_out in posizione cont-esima sia 1 e tutti gli altri 0
                        distanzaMinima <= distanzaManhattanAttuale;                                   --aggiorniamo la distanza minima che è il nostro segnale di soglia(distanza minima trovata fino alla cont-esima iterazione)
                        cont <= STD_LOGIC_VECTOR(UNSIGNED(cont) + 1);                                 --incremento il contatore                                
                        nextState <= S5;
                    elsif distanzaManhattanAttuale = distanzaMinima then                              --se la distanza di Manhattan, calcolata durante l'iterazione attuale, Ë uguale alla soglia, ovvero della distanza minima corrente, entriamo in questo ramo if
                        mask_out <= STD_LOGIC_VECTOR(UNSIGNED(mask_out) + UNSIGNED(updateMask));      --assegnamo al bit di mask_out in posizione cont-esima il valore 1, sommandoci il segnale updateMask (che ha in posizione cont-esima il valore 1 e tutti gli altri bit 0)
                        cont <= STD_LOGIC_VECTOR(UNSIGNED(cont) + 1);                                 --incremento contatore                                
                        nextState <= S5;
                    else                                                                              --se la distanza di Manhattan, calcolata durante l'iterazione attuale, Ë maggiore della soglia, ovvero della distanza minima corrente, non aggiorniamo la maschera di uscita
                        cont <= STD_LOGIC_VECTOR(UNSIGNED(cont) + 1);                                 --incremento il contatore                                
                        nextState <= S5;
                    end if;
              when S12 =>
                     o_done <= '1';                                                                   --imposto o_done a 1 in modo tale che nello stato prossimo il modulo HW progettato notifichi la fine dell'elaborazione
                     nextState <= S13;
              when S13 =>
                    if i_start='1' then
                        nextState <= S13;
                    else    
                        mask_out <= (others => '0');                                                  --riassegno a tutti i segnali del nostro circuito i valori di inizializzazione(dati al primo assegnamento all 'interno dell architecture)in modo che la macchina sia ?pronta ad iniziare una nuova computazione senza avere inconsistenza sui valori dei segnali
                        mask_in <= (others => '0'); 
                        updateMask <= (others => '0');
                        xPoint <= (others => '0');
                        yPoint <= (others => '0');
                        distanzaMinima <= (8 downto 1 => '1', others => '0');
                        distanzaManhattanAttuale <= (others => '0');
                        distanzaXcentroide <= (others => '0');
                        distanzaYcentroide <= (others => '0');
                        xcentroide <= (others => '0');
                        ycentroide <= (others => '0');
                        cont <= (others => '0');
					    o_address <= (others => '0');
                        o_done <= '0';
                        o_en <= '0';
                        o_we <= '0';
                        o_data <= (others => '0');
                        nextState <= reset;
                    end if;
            end case;
        end if;                
    end process;
end myComponent;