library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;    -- for numeric conversions
use std.textio.all;          -- for file operations

entity TB_P4_ADDER is
end TB_P4_ADDER;

architecture TEST of TB_P4_ADDER is

    -- ============================
    -- CONSTANTS
    -- ============================
    constant NBITS : integer := 32;

    -- ============================
    -- SIGNALS
    -- ============================
    signal A, B : std_logic_vector(NBITS-1 downto 0);
    signal Cin  : std_logic;
    signal Sum  : std_logic_vector(NBITS-1 downto 0);
    signal Cout : std_logic;

    signal clk  : std_logic := '0';
    signal stop_sim : boolean := false;

    -- ============================
    -- FILE
    -- ============================
    file results_file : text open write_mode is "adder_results.txt";

    -- ============================
    -- COMPONENT
    -- ============================
    component P4_ADDER is
        generic (
            NBIT : integer := 32);
        port (
            A : in std_logic_vector(NBIT-1 downto 0);
            B : in std_logic_vector(NBIT-1 downto 0);
            Cin : in std_logic;
            S : out std_logic_vector(NBIT-1 downto 0);
            Cout : out std_logic);
    end component;
    
begin

    -- ============================
    -- DUT
    -- ============================
    DUT: P4_ADDER
        generic map (
            NBIT => NBITS
        )
        port map (
            A => A,
            B => B,
            Cin => Cin,
            S => Sum,
            Cout => Cout
        );

    -- ============================
    -- CLOCK (1 GHz -> 1 ns period)
    -- ============================
    clk_process : process
    begin
        while not stop_sim loop
            clk <= '0';
            wait for 0.5 ns;
            clk <= '1';
            wait for 0.5 ns;
        end loop;
        wait;
    end process;

    -- ============================
    -- STIMULUS
    -- ============================
    stim_proc : process

        variable a_int, b_int : integer;
        variable result_int   : integer;
        variable line_out     : line;

    begin

        wait until rising_edge(clk);
      
        -- ==========================================
        -- 1) BINARY TESTS (HEXADECIMAL FORMAT)
        -- ==========================================
        A <= x"00000001"; B <= x"00000001"; Cin <= '0';
        wait until rising_edge(clk);

        A <= x"0000000A"; B <= x"00000005"; Cin <= '0';
        wait until rising_edge(clk);

        -- ==========================================
        -- 2) numeric_std TESTS (DECIMAL FORMAT)
        -- ==========================================
        A <= std_logic_vector(to_unsigned(100, NBITS));
        B <= std_logic_vector(to_unsigned(25, NBITS));
        Cin <= '0';
        wait until rising_edge(clk);

        A <= std_logic_vector(to_unsigned(1000, NBITS));
        B <= std_logic_vector(to_unsigned(500, NBITS));
        Cin <= '1';
        wait until rising_edge(clk);

        -- ==========================================
        -- 3) FILE LOGGING -> "adder_results.txt"
        -- ==========================================
        for i in 0 to 20 loop
            a_int := i * 3;
            b_int := i * 5;

            A <= std_logic_vector(to_unsigned(a_int, NBITS));
            B <= std_logic_vector(to_unsigned(b_int, NBITS));
            Cin <= '0';

            wait until rising_edge(clk);

            result_int := to_integer(unsigned(Sum));

            write(line_out, string'("A="));
            write(line_out, a_int);
            write(line_out, string'(" B="));
            write(line_out, b_int);
            write(line_out, string'(" SUM="));
            write(line_out, result_int);

            writeline(results_file, line_out);
        end loop;

        -- ==========================================
        -- 4) ASSERT TESTING (SELF-CHECKING)
        -- ==========================================
        for i in 0 to 20 loop
            for j in 0 to 20 loop

                A <= std_logic_vector(to_unsigned(i, NBITS));
                B <= std_logic_vector(to_unsigned(j, NBITS));
                Cin <= '0';

                wait until rising_edge(clk);

                result_int := to_integer(unsigned(Sum));

                assert result_int = (i + j)
                report "ERROR: A=" & integer'image(i) &
                       " B=" & integer'image(j) &
                       " Expected=" & integer'image(i+j) &
                       " Got=" & integer'image(result_int)
                severity error;

            end loop;
        end loop;

        -- ==========================================
        -- END SIMULATION
        -- ==========================================
        stop_sim <= true;
        wait;

    end process;

end TEST;
