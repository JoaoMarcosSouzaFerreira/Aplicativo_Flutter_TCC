# laboratorio_controle

Projeto desenvolvido para controlar uma bancada via protocolo MQTT e utilizando um broker Mosquitto.

Para utilizar o aplicativo o usuário deve fornecer informações a respeito do seu grupo e posteriormente os dados (IP e porta) do broker para efetuar a conexão.

Após conexão bem sucedida serão solicitados os dados dos parâmetros do experimento.

Os dados serão enviados via protocolo MQTT para o broker, onde serão lidos pela bancada que possuí um ESP 32 que está conectado como subescritor e irá receber estes parâmetros e iniciar o experimento.

A medida que o experimento avança, na terceira tela será mostrado um feedback em tempo real do experimento - (com possiblidade de Stream do experimento*).

Ao final o usuário poderá: visualizar os dados coletados, armazená-lós em seu dispositivo móvel ou descartá-los.

*-Atualização caso seja possível implementar módulo de câmera na bancada

