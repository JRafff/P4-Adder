library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity TB_CARRYGEN is 
end TB_CARRYGEN; 

architecture TEST of TB_CARRYGEN is

    constant N      : integer := 32;
    constant Ncarry : integer := 4;
    constant LEVELS : integer := 5;

    signal A_tb, B_tb : std_logic_vector(N-1 downto 0);
    signal cin_tb : std_logic;
    signal cout_tb : std_logic_vector((N/Ncarry)-1 downto 0);
    
    signal true_cout : std_logic_vector((N/Ncarry)-1 downto 0);
    signal somma : std_logic_vector(N-1 downto 0);


	component carryGEN is
		generic ( 
        N       : integer := 32;
        Ncarry  : integer := 4;
        LEVELS  : integer := 5  );
    port (
        A       : in  std_logic_vector(N-1 downto 0) := (others => '0');
        B       : in  std_logic_vector(N-1 downto 0) := (others => '0');
        c_in    : in  std_logic := '0';
        c_out   : out std_logic_vector((N/Ncarry)-1 downto 0)
    );
	end component;


begin

    dut: carryGEN 
    generic map(N => N, Ncarry => Ncarry, LEVELS => LEVELS)
    port map(A_tb, B_tb, cin_tb, cout_tb);

    somma <= ((A_tb) + (B_tb) + (cin_tb));

    calcolo_carry: process(A_tb, B_tb, cin_tb)
    variable sum : std_logic_vector(Ncarry downto 0);
    variable k: std_logic;
    begin
        -- Il primo carry in entrata è il nostro cin_tb
        k := cin_tb;
        for i in 1 to (N/Ncarry) loop
            sum := (('0'&A_tb((Ncarry*i -1) downto (Ncarry*(i - 1)))) + ('0'&B_tb((Ncarry*i -1) downto (Ncarry*(i - 1)))) + (k));
            true_cout(i-1) <= sum(Ncarry);
            k := sum(Ncarry);
        end loop;

    end process;



    undertest: process 
    begin
        -- Tutti i bit a zero, Cin = 0
        A_tb <= (others => '0');
        B_tb <= (others => '0');
        cin_tb <= '0';

        wait for 10 ns; -- Aspetto che il circuito propaghi il segnale

        -- propagazione estrema 
        A_tb <= x"FFFFFFFF"; -- Tutti 1
        B_tb <= x"00000000"; -- Tutti 0
        cin_tb <= '1';       -- Inietto 1. Tutti i carry devono accendersi
        wait for 10 ns;

        -- Altri 
        A_tb <= x"00000FFF"; 
        B_tb <= x"00000001"; 
        cin_tb <= '0';       
        wait for 10 ns;

       A_tb <= x"00000FFF"; 
        B_tb <= x"000FF000"; 
        cin_tb <= '1';       
        wait for 10 ns;

        A_tb <= x"00000688"; 
        B_tb <= x"00000391"; 
        cin_tb <= '0';       
        wait for 10 ns;

        wait; -- Ferma tutto a fine test

    end process;




end TEST;


configuration CFG_TB_CARRYGEN of TB_CARRYGEN is
  for TEST
    for all: carryGEN
      use entity WORK.carryGEN(structural);
    end for;
  end for;
end CFG_TB_CARRYGEN;
